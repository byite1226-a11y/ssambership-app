import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/design/tokens/color_tokens.dart';
import 'package:ssambership_app/features/mentors/ui/widgets/mentor_meta_item.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('아이콘 + 텍스트를 함께 렌더한다', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const MentorMetaItem(
      icon: Icons.school_rounded,
      text: 'KAIST · 물리학과',
    )));
    expect(find.text('KAIST · 물리학과'), findsOneWidget);
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });

  testWidgets('아이콘 색 기본은 secondary 토큰', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
        const MentorMetaItem(icon: Icons.payments_rounded, text: '29,900원부터')));
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, ColorTokens.secondary);
    expect(icon.size, 16);
  });
}
