import 'device_token_registrar.dart';
import 'push_ports.dart';
import 'push_types.dart';

/// 푸시 알림 클라이언트 오케스트레이션(골격).
///
/// ★ 패키지·서버 없이 컴파일된다: 기본 포트는 Disabled/Noop(HANDOFF.md 참조).
///   - 권한: "답변을 놓치지 않으려면 알림을 켜세요" 맥락에서 1회 요청([requestPermissionOnce]).
///   - 거부 시 마이페이지에서 재요청([requestPermissionAgain]) — 연결 지점은 인수인계.
///   - 토큰: 발급 가능하고 등록 준비되면 사용자 계정에 등록.
///   화면에 토큰/내부 id 를 절대 노출하지 않는다.
class PushService {
  PushService({
    PushPermissionPort permission = const DisabledPushPermission(),
    PushTokenProvider tokenProvider = const DisabledPushTokenProvider(),
    DeviceTokenRegistrarPort registrar = const SupabaseDeviceTokenRegistrar(),
  })  : _permission = permission,
        _tokenProvider = tokenProvider,
        _registrar = registrar;

  /// 앱 기본 인스턴스(기본 포트 = 미도입 안전 골격).
  static final PushService instance = PushService();

  final PushPermissionPort _permission;
  final PushTokenProvider _tokenProvider;
  final DeviceTokenRegistrarPort _registrar;

  PushPermissionStatus _lastStatus = PushPermissionStatus.notDetermined;
  bool _requestedOnce = false;

  PushPermissionStatus get lastStatus => _lastStatus;

  /// 이번 실행에서 권한을 한 번이라도 물어봤는지(중복 팝업 방지용).
  bool get hasRequestedOnce => _requestedOnce;

  /// main() 1회 호출(무인자 호환). 현재 권한 확인 → 이미 허용이면 토큰 등록 시도.
  Future<void> initialize({String? userId}) async {
    _lastStatus = await _permission.current();
    if (_lastStatus.isGranted && userId != null) {
      await registerCurrentToken(userId);
    }
  }

  /// 알림 켜기 유도 후 '1회' 권한 요청. 이미 물어봤으면 재요청 없이 마지막 상태 반환.
  Future<PushPermissionStatus> requestPermissionOnce({String? userId}) async {
    if (_requestedOnce) return _lastStatus;
    _requestedOnce = true;
    _lastStatus = await _permission.request();
    if (_lastStatus.isGranted && userId != null) {
      await registerCurrentToken(userId);
    }
    return _lastStatus;
  }

  /// 거부 후 재요청(once 플래그 무시). ★ 마이페이지 설정 진입점에서 호출(연결은 인수인계).
  Future<PushPermissionStatus> requestPermissionAgain({String? userId}) async {
    _requestedOnce = true;
    _lastStatus = await _permission.request();
    if (_lastStatus.isGranted && userId != null) {
      await registerCurrentToken(userId);
    }
    return _lastStatus;
  }

  /// 현재 디바이스 토큰을 사용자 계정에 등록(가능할 때만). 미도입/미준비면 조용히 건너뛴다.
  Future<void> registerCurrentToken(String userId) async {
    if (!_tokenProvider.isAvailable || !_registrar.isReady) return;
    final String? token = await _tokenProvider.getToken();
    if (token == null || token.isEmpty) return;
    await _registrar.register(userId: userId, token: token);
  }

  /// 로그아웃 시 토큰 해제(가능할 때만).
  Future<void> unregister(String token) async {
    if (!_registrar.isReady) return;
    await _registrar.unregister(token: token);
  }
}
