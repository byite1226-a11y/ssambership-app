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
  testWidgets('미확정: 충전 → "충전은 웹에서" 안내(앱 결제화면 없음)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_button((BuildContext c) => openRechargeWeb(c)));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('충전은 웹에서'), findsOneWidget);
  });

  testWidgets('미확정: 구독 → "구독은 웹에서" 안내', (WidgetTester tester) async {
    await tester
        .pumpWidget(_button((BuildContext c) => openSubscribeWeb(c, mentorId: 'm1')));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('구독은 웹에서'), findsOneWidget);
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
    await tester.pumpWidget(_button(
        (BuildContext c) => openSubscribeWeb(c, mentorId: 'm1', bridge: bridge)));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(opened.length, 1);
    expect(opened.single.queryParameters['mentor'], 'm1');
    // 열렸으므로 안내 스낵바 없음(웹으로 이동).
    expect(find.textContaining('웹에서'), findsNothing);
  });
}
