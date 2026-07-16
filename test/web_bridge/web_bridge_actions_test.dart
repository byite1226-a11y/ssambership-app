import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/web_bridge/web_bridge.dart';
import 'package:ssambership_app/core/web_bridge/web_bridge_actions.dart';

Widget _button(Future<void> Function(BuildContext context) onTap) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext c) =>
              TextButton(onPressed: () => onTap(c), child: const Text('go')),
        ),
      ),
    );

void main() {
  // baseUrl 미확정(빈 값) 폴백을 명시 주입으로 검증한다.
  // (기본 WebBridgeConfig.baseUrl 은 이제 설정돼 있으므로 빈 브릿지를 주입해야
  //  '준비 중' 폴백 경로가 재현된다.)
  // ★ 구매 유도 헬퍼(구독·충전)는 P0-3 死배선 정리로 삭제 — 관리 헬퍼로 검증한다.
  testWidgets('미확정: 결제·구독 관리 → "웹에서 할 수 있어요" 안내(앱 결제화면 없음)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_button((BuildContext c) =>
        openBillingManageWeb(c, bridge: WebBridge(baseUrl: ''))));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('결제·구독 관리는 웹에서'), findsOneWidget);
  });

  testWidgets('미확정: 정산 관리 → "정산 관리는 웹에서" 안내', (WidgetTester tester) async {
    await tester.pumpWidget(_button((BuildContext c) =>
        openPayoutManageWeb(c, bridge: WebBridge(baseUrl: ''))));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('정산 관리는 웹에서'), findsOneWidget);
  });

  testWidgets('설정 완료(주입): 열기 성공 → 안내 없음 + 올바른 URL',
      (WidgetTester tester) async {
    final List<Uri> opened = <Uri>[];
    final WebBridge bridge = WebBridge(
      baseUrl: 'https://web.test',
      launcher: (Uri u) async {
        opened.add(u);
        return true;
      },
    );
    await tester.pumpWidget(
        _button((BuildContext c) => openBillingManageWeb(c, bridge: bridge)));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(opened.length, 1);
    expect(opened.single.queryParameters['src'], 'app');
    // 열렸으므로 안내 스낵바 없음(웹으로 이동).
    expect(find.textContaining('웹에서'), findsNothing);
  });
}
