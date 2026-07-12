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

    test('openBillingManage: billingManagePath + src 쿼리 반영', () async {
      final WebOpenResult r = await make().openBillingManage();
      expect(r, WebOpenResult.opened);
      expect(opened.single.origin, 'https://web.test');
      expect(opened.single.path, WebBridgeConfig.billingManagePath);
      expect(opened.single.queryParameters['src'], 'app');
    });

    test('buildUri: 추가 쿼리는 기존 쿼리와 병합된다', () {
      final Uri? uri = make().buildUri(
        WebBridgeConfig.billingManagePath,
        <String, String>{'src': 'app', 'from': 'mypage'},
      );
      expect(uri, isNotNull);
      expect(uri!.queryParameters['src'], 'app');
      expect(uri.queryParameters['from'], 'mypage');
    });

    test('결제관리/정산/프로필 각 경로로 조립', () async {
      final WebBridge b = make();
      await b.openBillingManage();
      await b.openPayoutManage();
      await b.openProfileEdit();
      expect(opened.map((Uri e) => e.path).toList(), <String>[
        WebBridgeConfig.billingManagePath,
        WebBridgeConfig.payoutManagePath,
        WebBridgeConfig.profileEditPath,
      ]);
    });

    test('openAccountDelete: accountDeletePath 로 조립', () async {
      final WebOpenResult r = await make().openAccountDelete();
      expect(r, WebOpenResult.opened);
      expect(opened.single.path, WebBridgeConfig.accountDeletePath);
      expect(opened.single.path, '/account/delete');
    });

    test('열기 실패 → failed', () async {
      final WebOpenResult r = await WebBridge(
        baseUrl: 'https://web.test',
        launcher: (Uri u) async => false,
      ).openBillingManage();
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
      expect(await b.openBillingManage(), WebOpenResult.notConfigured);
      expect(await b.openPayoutManage(), WebOpenResult.notConfigured);
      expect(called, false); // 가짜 URL 을 만들지도, 열지도 않는다.
      expect(b.buildUri(WebBridgeConfig.billingManagePath), isNull);
    });

    test('기본 WebBridge() 는 WebBridgeConfig 설정값을 그대로 반영', () {
      // 운영 도메인 확정(2026-07): 기본 빌드는 설정됨 → URL 조립 가능.
      // baseUrl 은 --dart-define=WEB_BASE_URL 로 주입 가능하므로, 빈 값 주입
      // 빌드에서는 '미설정 반영'만 검증한다(주입 겸용 — 어느 모드든 녹색).
      expect(WebBridge().isConfigured, WebBridgeConfig.isConfigured);
      if (!WebBridgeConfig.isConfigured) return; // 빈 값 주입 모드: 여기까지.
      final Uri? uri = WebBridge().buildUri(WebBridgeConfig.billingManagePath);
      expect(uri, isNotNull);
      expect(uri!.origin, WebBridgeConfig.baseUrl);
      expect(uri.path, WebBridgeConfig.billingManagePath);
    });
  });
}
