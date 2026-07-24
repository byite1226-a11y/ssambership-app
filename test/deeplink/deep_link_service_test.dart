import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/app/app_tabs.dart';
import 'package:ssambership_app/core/deeplink/deep_link_service.dart';
import 'package:ssambership_app/core/push/push_payload.dart';
import 'package:ssambership_app/core/push/push_ports.dart';
import 'package:ssambership_app/core/push/push_service.dart';

import '../push/push_fakes.dart';

/// 배선 검증: 푸시 '탭' 스트림 → DeepLinkService → TabNavigator.go (fake 게이트웨이).
void main() {
  late FakePushGateway gateway;
  late PushService push;

  PushPayload payload({
    String type = 'question_answered',
    String? roomId = 'r-1',
    String eventId = 'n-1',
  }) {
    return PushPayload.fromRemote(<String, dynamic>{
      'type': type,
      if (roomId != null) 'room_id': roomId,
      'notification_id': eventId,
    });
  }

  setUp(() {
    TabNavigator.request.value = -1;
    gateway = FakePushGateway();
    push = PushService(
      gateway: gateway,
      permission: FakePermission(PushPermissionStatus.notDetermined),
      registrar: FakeRegistrar(),
      platform: 'android',
    );
  });

  tearDown(() async {
    await DeepLinkService.instance.dispose();
    TabNavigator.request.value = -1;
  });

  test('알림 탭(onMessageOpened) → TabNavigator 로 탭 전환 요청', () async {
    await DeepLinkService.instance.initialize(pushService: push);
    DeepLinkService.instance.onSignedIn('u-1');
    await push.initialize();

    gateway.opened.add(payload());
    await pumpEventQueue();

    expect(TabNavigator.request.value, AppTab.questionRoom);
  });

  test('콜드 스타트 최초 메시지도 딥링크로 처리된다(초기화 순서: 딥링크 → 푸시)', () async {
    gateway.initialMessage = payload(
      type: 'subscription_expired',
      roomId: null,
      eventId: 'n-cold',
    );
    await DeepLinkService.instance.initialize(pushService: push);
    DeepLinkService.instance.onSignedIn('u-1');
    await push.initialize();
    await pumpEventQueue();

    expect(TabNavigator.request.value, AppTab.myPage);
  });

  test('포그라운드 수신(onMessage)은 이동을 일으키지 않는다(탭만 딥링크)', () async {
    await DeepLinkService.instance.initialize(pushService: push);
    DeepLinkService.instance.onSignedIn('u-1');
    await push.initialize();

    gateway.foreground.add(payload(eventId: 'n-fg'));
    await pumpEventQueue();

    expect(TabNavigator.request.value, -1);
  });

  test('비로그인 탭 → 보류, onSignedIn 훅에서 1회 실행', () async {
    await DeepLinkService.instance.initialize(pushService: push);
    await push.initialize();

    gateway.opened.add(payload());
    await pumpEventQueue();
    expect(TabNavigator.request.value, -1); // 아직 이동 없음.

    DeepLinkService.instance.onSignedIn('u-1');
    expect(TabNavigator.request.value, AppTab.questionRoom);
  });
}
