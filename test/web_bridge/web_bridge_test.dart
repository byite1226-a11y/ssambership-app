import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/web_bridge/web_bridge.dart';
import 'package:ssambership_app/core/web_bridge/web_bridge_config.dart';

void main() {
  group('설정 완료(baseUrl 주입): URL 조립 + 열기', () {
    late List<Uri> opened;
    WebBridge make() => WebBridge(
          baseUrl: 'https://web.test',
          launcher: (Uri u) async {
            opened.add(u);
            return true;
          },
        );

    setUp(() => opened = <Uri>[]);

    test('openSubscribe: subscribePath + mentor 쿼리 반영', () async {
      final WebOpenResult r = await make().openSubscribe(mentorId: 'm-123');
      expect(r, WebOpenResult.opened);
      expect(opened.single.origin, 'https://web.test');
      expect(opened.single.path, WebBridgeConfig.subscribePath);
      expect(opened.single.queryParameters['mentor'], 'm-123');
      expect(opened.single.queryParameters['src'], 'app');
    });

    test('openSubscribe: mentorId 없으면 mentor 쿼리 없음', () async {
      await make().openSubscribe();
      expect(opened.single.queryParameters.containsKey('mentor'), false);
    });

    test('충전/결제관리/정산/프로필 각 경로로 조립', () async {
      final WebBridge b = make();
      await b.openRecharge();
      await b.openBillingManage();
      await b.openPayoutManage();
      await b.openProfileEdit();
      expect(opened.map((Uri e) => e.path).toList(), <String>[
        WebBridgeConfig.rechargePath,
        WebBridgeConfig.billingManagePath,
        WebBridgeConfig.payoutManagePath,
        WebBridgeConfig.profileEditPath,
      ]);
    });

    test('열기 실패 → failed', () async {
      final WebOpenResult r = await WebBridge(
        baseUrl: 'https://web.test',
        launcher: (Uri u) async => false,
      ).openSubscribe();
      expect(r, WebOpenResult.failed);
    });
  });

  group('미확정(baseUrl 비었음): 열지 않고 안내 폴백', () {
    test('launcher 미호출 + notConfigured + buildUri null', () async {
      bool called = false;
      final WebBridge b = WebBridge(
        baseUrl: '',
        launcher: (Uri u) async {
          called = true;
          return true;
        },
      );
      expect(await b.openSubscribe(mentorId: 'x'), WebOpenResult.notConfigured);
      expect(await b.openRecharge(), WebOpenResult.notConfigured);
      expect(called, false); // 가짜 URL 을 만들지도, 열지도 않는다.
      expect(b.buildUri(WebBridgeConfig.subscribePath), isNull);
    });

    test('기본 WebBridge() 는 WebBridgeConfig 설정값을 그대로 반영', () {
      // 오너가 baseUrl 을 채운 뒤: 기본 생성자도 설정됨 → URL 조립 가능.
      // (실제 열기는 플랫폼 런처라 유닛에서 호출하지 않고 buildUri 로 확인.)
      expect(WebBridge().isConfigured, WebBridgeConfig.isConfigured);
      expect(WebBridgeConfig.isConfigured, isTrue);
      final Uri? uri = WebBridge().buildUri(WebBridgeConfig.subscribePath);
      expect(uri, isNotNull);
      expect(uri!.origin, 'https://ssambership-web.vercel.app');
      expect(uri.path, WebBridgeConfig.subscribePath);
    });
  });
}
