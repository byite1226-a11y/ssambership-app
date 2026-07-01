import 'push_payload.dart';
import 'push_types.dart';

/// 푸시 인프라 '포트'(추상 경계). ★ 패키지·서버 없이 컴파일되도록 기본은 Disabled/Noop.
///   실제 구현(FCM 토큰·OS 권한·Edge Function)은 동업자 인수인계(HANDOFF.md 참조).

/// FCM 등에서 디바이스 토큰을 얻는 포트. 실제 구현은 firebase_messaging 도입 후.
abstract class PushTokenProvider {
  /// 토큰 발급/획득. 미도입이면 null.
  Future<String?> getToken();

  /// 토큰 갱신 스트림(회전 시 재등록용).
  Stream<String> get onTokenRefresh;

  /// 사용 가능 여부(패키지·플랫폼 준비).
  bool get isAvailable;
}

/// 기본: 미도입(firebase_messaging 없음) — 토큰 없음.
class DisabledPushTokenProvider implements PushTokenProvider {
  const DisabledPushTokenProvider();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
}

/// OS 알림 권한 포트. 실제 권한 팝업은 모바일 빌드(인수인계).
abstract class PushPermissionPort {
  Future<PushPermissionStatus> current();
  Future<PushPermissionStatus> request();
}

/// 기본: 미결정 고정(권한 API 미연결). 실제 구현이 붙기 전까지 골격 동작.
class DisabledPushPermission implements PushPermissionPort {
  const DisabledPushPermission();

  @override
  Future<PushPermissionStatus> current() async =>
      PushPermissionStatus.notDetermined;

  @override
  Future<PushPermissionStatus> request() async =>
      PushPermissionStatus.notDetermined;
}

/// 디바이스 토큰을 사용자 계정에 등록/해제하는 포트(device_tokens 테이블 대상).
abstract class DeviceTokenRegistrarPort {
  /// 등록 가능 상태(테이블·권한 준비). 미준비면 서비스가 등록을 건너뛴다.
  bool get isReady;

  Future<void> register({
    required String userId,
    required String token,
    String platform,
  });

  Future<void> unregister({required String token});
}

/// 기본: 미등록(테이블 미존재 등) — 아무 것도 하지 않음.
class NoopDeviceTokenRegistrar implements DeviceTokenRegistrarPort {
  const NoopDeviceTokenRegistrar();

  @override
  bool get isReady => false;

  @override
  Future<void> register({
    required String userId,
    required String token,
    String platform = 'android',
  }) async {}

  @override
  Future<void> unregister({required String token}) async {}
}

/// 서버(Edge Function)로 푸시 발송을 요청하는 포트. 실제 배포·호출은 인수인계.
abstract class PushSenderPort {
  /// 발송 가능 상태(Edge Function 배포됨). 미배포면 트리거가 건너뛴다.
  bool get isReady;

  /// 특정 사용자에게 payload 발송 요청.
  Future<void> send(PushPayload payload, {required String toUserId});
}

/// 기본: 미배포 — 발송하지 않음(트리거 지점만 준비).
class NoopPushSender implements PushSenderPort {
  const NoopPushSender();

  @override
  bool get isReady => false;

  @override
  Future<void> send(PushPayload payload, {required String toUserId}) async {}
}
