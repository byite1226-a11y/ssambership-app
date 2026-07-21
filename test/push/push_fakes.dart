import 'dart:async';

import 'package:ssambership_app/core/push/push_payload.dart';
import 'package:ssambership_app/core/push/push_ports.dart';
import 'package:ssambership_app/shared/errors/app_error.dart';

/// 실제 OS 권한·Firebase·서버 없이 주입할 가짜 포트(호출 기록만 — mocktail 미사용).

class FakePermission implements PushPermissionPort {
  FakePermission(this.status);

  PushPermissionStatus status;
  int currentCount = 0;
  int requestCount = 0;

  @override
  Future<PushPermissionStatus> current() async {
    currentCount++;
    return status;
  }

  @override
  Future<PushPermissionStatus> request() async {
    requestCount++;
    return status;
  }
}

class FakePushGateway implements PushGatewayPort {
  FakePushGateway({this.ready = true, this.token = 'tok-1'});

  bool ready;
  String? token;
  int initializeCount = 0;
  int getTokenCount = 0;

  /// 콜드 스타트 최초 메시지(getInitialMessage 반환값).
  PushPayload? initialMessage;

  final StreamController<String> tokenRefresh =
      StreamController<String>.broadcast(sync: true);
  final StreamController<PushPayload> foreground =
      StreamController<PushPayload>.broadcast(sync: true);
  final StreamController<PushPayload> opened =
      StreamController<PushPayload>.broadcast(sync: true);

  @override
  Future<bool> initialize() async {
    initializeCount++;
    return ready;
  }

  @override
  bool get isReady => ready;

  @override
  Future<String?> getToken() async {
    getTokenCount++;
    return ready ? token : null;
  }

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<PushPayload> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushPayload> get onMessageOpened => opened.stream;

  @override
  Future<PushPayload?> getInitialMessage() async => initialMessage;
}

/// 등록/철회 호출을 순서대로 기록하는 가짜 레지스트라.
/// [journal] 을 넘기면 외부 로그에도 순서를 남긴다(로그아웃 순서 검증용).
class FakeRegistrar implements DeviceTokenRegistrarPort {
  FakeRegistrar({this.ready = true, this.journal});

  bool ready;
  final List<String>? journal;

  /// 앞으로 n 번의 register 를 실패시킨다(재시도 가능 상태 검증용).
  int failNextRegisters = 0;

  final List<String> registeredTokens = <String>[];
  final List<String> registeredPlatforms = <String>[];
  final List<String> revokedTokens = <String>[];
  String nextDeviceTokenId = 'dtid-1';

  int get registerCount => registeredTokens.length;
  int get revokeCount => revokedTokens.length;

  @override
  bool get isReady => ready;

  @override
  Future<String?> register({
    required String token,
    required String platform,
  }) async {
    if (failNextRegisters > 0) {
      failNextRegisters--;
      throw const AppError('알림 등록에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
    registeredTokens.add(token);
    registeredPlatforms.add(platform);
    journal?.add('register');
    return nextDeviceTokenId;
  }

  @override
  Future<void> revoke({required String token}) async {
    revokedTokens.add(token);
    journal?.add('revoke');
  }
}

/// 철회가 항상 실패하는 레지스트라(로그아웃 비차단 검증용).
class FailingRevokeRegistrar extends FakeRegistrar {
  FailingRevokeRegistrar({super.journal});

  @override
  Future<void> revoke({required String token}) async {
    journal?.add('revoke-failed');
    throw const AppError('알림 해제에 실패했어요.');
  }
}
