import 'push_payload.dart';

/// 푸시 인프라 '포트'(추상 경계).
///
/// ★ 앱은 푸시 '수신·토큰 등록'만 담당한다 — 발송은 서버 outbox worker 단독
///   (record_domain_notification → notification_outbox → deliveries).
///   클라이언트 발송 경로(PushSenderPort/PushTrigger)는 제거됨.
/// ★ Firebase 설정 파일이 없으면 게이트웨이가 ready=false 로 조용히 비활성화되어
///   패키지만으로도 컴파일·구동된다(lib/core/push/HANDOFF.md 활성화 절차 참조).

/// 알림 권한 상태(플랫폼 무관 추상).
///
/// ★ '영구 거부'와 '이번만 거부'의 구분은 firebase_messaging 단독으로는 제한적이다
///   (Android 13+ 는 두 번 거부하면 시스템이 팝업을 더 띄우지 않지만 API 는 동일하게
///   denied 만 반환). 추가 플러그인(permission_handler) 없이는 denied 하나로 다루고,
///   재요청 UI 는 '설정에서 켜기' 안내로 폴백한다.
enum PushPermissionStatus {
  /// 아직 물어보지 않음.
  notDetermined,

  /// 허용됨(iOS provisional 포함).
  granted,

  /// 거부됨(마이페이지에서 재요청/설정 유도 가능).
  denied;

  bool get isGranted => this == PushPermissionStatus.granted;
}

/// OS 알림 권한 포트. 실제 구현은 FirebasePushPermission(firebase_push_gateway.dart).
abstract class PushPermissionPort {
  Future<PushPermissionStatus> current();
  Future<PushPermissionStatus> request();
}

/// 기본: 미결정 고정(권한 API 미연결). Firebase 설정 전 골격 동작용.
class DisabledPushPermission implements PushPermissionPort {
  const DisabledPushPermission();

  @override
  Future<PushPermissionStatus> current() async =>
      PushPermissionStatus.notDetermined;

  @override
  Future<PushPermissionStatus> request() async =>
      PushPermissionStatus.notDetermined;
}

/// 푸시 게이트웨이 포트 — 초기화·토큰·수신 스트림(FCM 추상).
///
/// [initialize] 가 실패하면([isReady]=false) 모든 호출이 no-op/빈 스트림이어야 한다
/// (설정 파일 부재 시에도 앱은 크래시 없이 계속).
abstract class PushGatewayPort {
  /// 1회 초기화. 실패해도 예외를 던지지 않고 false 를 반환한다.
  Future<bool> initialize();

  /// 초기화 성공 여부. false 면 서비스가 토큰/수신을 건너뛴다.
  bool get isReady;

  /// 현재 디바이스 토큰(미준비/실패 시 null). ★ 토큰 문자열은 절대 로그 금지.
  Future<String?> getToken();

  /// 토큰 회전 스트림(재등록용).
  Stream<String> get onTokenRefresh;

  /// 포그라운드 수신(앱 사용 중 도착 — UI 없이 인앱 갱신 훅용).
  Stream<PushPayload> get onForegroundMessage;

  /// 백그라운드 알림 '탭'으로 앱이 열림.
  Stream<PushPayload> get onMessageOpened;

  /// 종료 상태에서 알림 탭으로 콜드 스타트한 경우의 최초 메시지(없으면 null).
  Future<PushPayload?> getInitialMessage();
}

/// 기본: 미도입/미설정 — 아무 것도 하지 않는 게이트웨이(테스트·골격용).
class DisabledPushGateway implements PushGatewayPort {
  const DisabledPushGateway();

  @override
  Future<bool> initialize() async => false;

  @override
  bool get isReady => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<PushPayload> get onForegroundMessage =>
      const Stream<PushPayload>.empty();

  @override
  Stream<PushPayload> get onMessageOpened => const Stream<PushPayload>.empty();

  @override
  Future<PushPayload?> getInitialMessage() async => null;
}

/// 디바이스 토큰 등록/철회 포트(서버 device_tokens 대상).
///
/// - 등록: RPC `register_device_token(p_token, p_platform)` — ON CONFLICT(token) 시
///   현재 auth.uid() 로 원자적 재소유 + revoked_at 해제(계정 전환은 재등록만으로 처리).
/// - 철회: `revoke_device_token` RPC 는 authenticated 실행권한이 없어 호출 금지 —
///   본인 행 직접 UPDATE(revoked_at)로 철회한다. 반드시 signOut '이전'에 호출.
abstract class DeviceTokenRegistrarPort {
  /// 등록 가능 상태(백엔드 연결됨). 미준비면 서비스가 등록을 건너뛴다.
  bool get isReady;

  /// 토큰 등록. 성공 시 서버 device_token_id 반환(실패는 예외 — 호출부가 재시도 가능 상태 유지).
  Future<String?> register({required String token, required String platform});

  /// 본인 토큰 철회(revoked_at 마킹). 세션이 살아 있는 동안(로그아웃 전) 호출.
  Future<void> revoke({required String token});
}
