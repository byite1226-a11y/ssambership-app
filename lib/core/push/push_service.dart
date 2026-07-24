import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'device_token_registrar.dart';
import 'firebase_push_gateway.dart';
import 'push_payload.dart';
import 'push_ports.dart';

/// 서버 register_device_token 이 유효 처리하는 플랫폼 코드(ios/android/web).
/// 그 외 값은 서버가 'unknown' 으로 저장한다 — 날조하지 않고 그대로 둔다.
String currentPushPlatform() {
  if (kIsWeb) return 'web';
  try {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
  } catch (_) {
    // 플랫폼 조회 불가 환경(테스트 등) — 아래 폴백.
  }
  return 'unknown';
}

/// 푸시 클라이언트 오케스트레이션 — '수신 + 토큰 수명주기' 전담.
///
/// ★ 발송은 서버 outbox worker 단독(record_domain_notification → notification_outbox
///   → deliveries). 앱은 FCM HTTP·Edge Function 호출 등 어떤 발송도 하지 않는다.
/// ★ 준비 경계: Firebase 설정 파일이 없으면 게이트웨이 ready=false → 모든 동작이
///   조용히 생략되고 앱은 정상 구동(HANDOFF: WAITING_EXTERNAL_FIREBASE_CONFIG).
/// ★ 토큰/디바이스 id 는 화면·로그에 절대 노출하지 않는다.
///
/// 토큰 수명주기:
/// - 로그인/세션 복원([onSignedIn]) → 권한 허용 + 게이트웨이 준비 시 getToken →
///   RPC register_device_token → device_token_id 기억.
/// - 토큰 회전(onTokenRefresh) → 재등록(서버 upsert 가 처리).
/// - 로그아웃([revokeBeforeSignOut]) → supabase signOut '이전'에 본인 행 revoked_at
///   마킹(실패해도 로그아웃은 진행 — 서버 재소유가 안전망).
/// - 계정 전환 → 새 로그인 후 재등록만 하면 서버가 원자적으로 재소유.
class PushService {
  PushService({
    PushGatewayPort? gateway,
    PushPermissionPort? permission,
    DeviceTokenRegistrarPort? registrar,
    String? platform,
  })  : _gateway = gateway ?? FirebasePushGateway(),
        _registrar = registrar ?? const SupabaseDeviceTokenRegistrar(),
        _platform = platform ?? currentPushPlatform() {
    _permission = permission ?? FirebasePushPermission(_gateway);
  }

  /// 앱 기본 인스턴스(실 게이트웨이 — 설정 없으면 스스로 비활성).
  static final PushService instance = PushService();

  final PushGatewayPort _gateway;
  final DeviceTokenRegistrarPort _registrar;
  final String _platform;
  late final PushPermissionPort _permission;

  final StreamController<PushPayload> _foreground =
      StreamController<PushPayload>.broadcast();
  final StreamController<PushPayload> _opened =
      StreamController<PushPayload>.broadcast();

  bool _initialized = false;
  PushPermissionStatus _lastStatus = PushPermissionStatus.notDetermined;
  bool _requestedOnce = false;

  String? _signedInUserId;
  String? _registeredToken;
  String? _deviceTokenId;

  PushPermissionStatus get lastStatus => _lastStatus;

  /// 이번 실행에서 권한을 한 번이라도 물어봤는지(중복 팝업 방지용).
  bool get hasRequestedOnce => _requestedOnce;

  /// 현재 토큰이 서버에 등록되어 있는지(내부 상태 — 값 자체는 비노출).
  bool get hasRegisteredToken => _registeredToken != null;

  /// 서버가 돌려준 device_token_id(로그·화면 비노출, 철회/디버그용 내부 참조).
  @visibleForTesting
  String? get deviceTokenIdForTest => _deviceTokenId;

  /// 포그라운드 수신(앱 사용 중 도착) — 알림함 갱신 등 인앱 훅용. UI 발명 없음.
  Stream<PushPayload> get onForegroundPayload => _foreground.stream;

  /// 알림 '탭'으로 열림(백그라운드 탭 + 콜드 스타트 최초 메시지 포함) — 딥링크 소비용.
  Stream<PushPayload> get onOpenedPayload => _opened.stream;

  /// main() 1회 호출. 게이트웨이 초기화 → 수신 스트림 연결 → (세션 있으면) 토큰 등록.
  /// 어떤 실패도 부팅을 막지 않는다.
  Future<void> initialize({String? userId}) async {
    if (_initialized) return;
    _initialized = true;
    final bool ready = await _gateway.initialize();
    if (!ready) return; // 설정 부재 — 수신·토큰·권한 조회 없이 앱 계속(준비 경계).
    _lastStatus = await _permission.current();

    _gateway.onForegroundMessage.listen(_foreground.add);
    _gateway.onMessageOpened.listen(_opened.add);
    _gateway.onTokenRefresh.listen(_onTokenRefresh);

    if (userId != null) _signedInUserId ??= userId;
    await _tryRegister();

    // 종료 상태에서 알림 탭으로 시작 — 딥링크 구독자(DeepLinkService)가
    // 먼저 initialize 되어 있어야 하므로 main 의 초기화 순서를 유지할 것.
    final PushPayload? initial = await _gateway.getInitialMessage();
    if (initial != null) _opened.add(initial);
  }

  /// 로그인/세션 복원 훅(AuthService). 권한 허용 + 준비 시 토큰 등록.
  Future<void> onSignedIn(String userId) async {
    _signedInUserId = userId;
    await _tryRegister();
  }

  /// 세션 소멸 훅(AuthService signedOut 이벤트) — 기억 상태만 정리.
  /// (정상 로그아웃 경로의 철회는 [revokeBeforeSignOut] 가 signOut '이전'에 수행.)
  void onSignedOut() {
    _signedInUserId = null;
    _registeredToken = null;
    _deviceTokenId = null;
  }

  /// 로그아웃 직전 호출(세션 유효 시점) — 본인 토큰 행 revoked_at 마킹.
  /// 실패해도 예외를 던지지 않는다(로그아웃 차단 금지). 기억 상태는 항상 정리.
  Future<void> revokeBeforeSignOut() async {
    final String? token = _registeredToken;
    _signedInUserId = null;
    _registeredToken = null;
    _deviceTokenId = null;
    if (token == null || !_registrar.isReady) return;
    try {
      await _registrar.revoke(token: token);
    } catch (_) {
      // 철회 실패 — 서버의 재소유(재등록 시)와 outbox 필터가 안전망. 토큰 로그 금지.
    }
  }

  /// 알림 켜기 유도 후 '1회' 권한 요청. 이미 물어봤으면 재요청 없이 마지막 상태 반환.
  Future<PushPermissionStatus> requestPermissionOnce({String? userId}) async {
    if (_requestedOnce) return _lastStatus;
    return requestPermissionAgain(userId: userId);
  }

  /// 거부 후 재요청(once 플래그 무시) — 마이페이지 설정 진입점용.
  /// 게이트웨이 미준비면 팝업 없이 현재 상태만 반환(no-op).
  Future<PushPermissionStatus> requestPermissionAgain({String? userId}) async {
    if (!_gateway.isReady) return _lastStatus;
    _requestedOnce = true;
    _lastStatus = await _permission.request();
    if (userId != null) _signedInUserId = userId;
    if (_lastStatus.isGranted) await _tryRegister();
    return _lastStatus;
  }

  /// 토큰 등록 시도 — 조건(로그인·준비·권한) 미충족이면 조용히 생략,
  /// 서버 실패면 기억 상태를 남기지 않아 다음 훅(재로그인·토큰 회전)에서 재시도된다.
  Future<void> _tryRegister() async {
    final String? userId = _signedInUserId;
    if (userId == null) return;
    if (!_gateway.isReady || !_registrar.isReady) return;
    if (!_lastStatus.isGranted) {
      _lastStatus = await _permission.current();
      if (!_lastStatus.isGranted) return;
    }
    final String? token = await _gateway.getToken();
    if (token == null || token.isEmpty) return;
    try {
      _deviceTokenId =
          await _registrar.register(token: token, platform: _platform);
      _registeredToken = token;
    } catch (_) {
      // 등록 실패 — 상태 미기억(재시도 가능). ★ 토큰 문자열 로그 금지.
      _registeredToken = null;
      _deviceTokenId = null;
    }
  }

  /// 토큰 회전 — 로그인 상태면 재등록(서버 upsert 가 기존 행 갱신/재소유).
  Future<void> _onTokenRefresh(String token) async {
    if (_signedInUserId == null) return;
    await _tryRegister();
  }
}
