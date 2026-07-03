import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/design/widgets/empty_state.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('아이콘·제목·본문을 렌더한다', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EmptyState(
      icon: Icons.bookmark_rounded,
      title: '구독 중인 멘토가 없어요',
      message: '관심 있는 멘토를 구독해 보세요',
    )));
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(find.text('구독 중인 멘토가 없어요'), findsOneWidget);
    expect(find.text('관심 있는 멘토를 구독해 보세요'), findsOneWidget);
  });

  testWidgets('CTA는 label+콜백이 있을 때만 노출된다', (WidgetTester tester) async {
    // 콜백/라벨 없음 → 버튼 없음.
    await tester.pumpWidget(_wrap(const EmptyState(
      icon: Icons.receipt_long_rounded,
      title: '거래 내역이 없어요',
    )));
    expect(find.text('멘토 찾기'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);

    // 라벨+콜백 있음 → 버튼 노출.
    await tester.pumpWidget(_wrap(EmptyState(
      icon: Icons.bookmark_rounded,
      title: '구독 중인 멘토가 없어요',
      actionLabel: '멘토 찾기',
      onAction: () {},
    )));
    expect(find.text('멘토 찾기'), findsOneWidget);
  });

  testWidgets('CTA 탭 시 콜백이 호출된다', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(_wrap(EmptyState(
      icon: Icons.bookmark_rounded,
      title: '구독 중인 멘토가 없어요',
      actionLabel: '멘토 찾기',
      onAction: () => calls++,
    )));
    await tester.tap(find.text('멘토 찾기'));
    await tester.pump();
    expect(calls, 1);
  });
}
