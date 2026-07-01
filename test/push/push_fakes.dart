import 'package:ssambership_app/core/push/push_payload.dart';
import 'package:ssambership_app/core/push/push_ports.dart';
import 'package:ssambership_app/core/push/push_types.dart';

/// 실제 OS 권한·FCM·서버 없이 주입할 가짜 포트(호출 기록만).
class FakePermission implements PushPermissionPort {
  FakePermission(this.status);
  PushPermissionStatus status;
  int requestCount = 0;

  @override
  Future<PushPermissionStatus> current() async => status;

  @override
  Future<PushPermissionStatus> request() async {
    requestCount++;
    return status;
  }
}

class FakeTokenProvider implements PushTokenProvider {
  FakeTokenProvider({this.available = true, this.token = 'tok-1'});
  final bool available;
  final String? token;

  @override
  bool get isAvailable => available;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
}

class FakeRegistrar implements DeviceTokenRegistrarPort {
  FakeRegistrar({this.ready = true});
  final bool ready;
  int registerCount = 0;
  String? registeredToken;
  String? registeredUser;

  @override
  bool get isReady => ready;

  @override
  Future<void> register({
    required String userId,
    required String token,
    String platform = 'android',
  }) async {
    registerCount++;
    registeredUser = userId;
    registeredToken = token;
  }

  @override
  Future<void> unregister({required String token}) async {}
}

class FakeSender implements PushSenderPort {
  FakeSender({this.ready = true});
  final bool ready;
  int sendCount = 0;
  PushPayload? lastPayload;
  String? lastTo;

  @override
  bool get isReady => ready;

  @override
  Future<void> send(PushPayload payload, {required String toUserId}) async {
    sendCount++;
    lastPayload = payload;
    lastTo = toUserId;
  }
}
