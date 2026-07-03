import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mypage/ui/widgets/mypage_section.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('icon 지정 시 제목 앞 아이콘을 렌더한다', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const MyPageSection(
      icon: Icons.settings_rounded,
      title: '설정',
      child: SizedBox.shrink(),
    )));
    expect(find.text('설정'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('icon 없으면 아이콘 없이 제목만(기존 동작)', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const MyPageSection(
      title: '설정',
      child: SizedBox.shrink(),
    )));
    expect(find.text('설정'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsNothing);
  });
}
