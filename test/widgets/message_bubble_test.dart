import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/models/question_message.dart';
import 'package:ssambership_app/features/question_room/ui/widgets/message_bubble.dart';

QuestionMessage _msg(String body) => QuestionMessage(
      id: 'm1',
      threadId: 't1',
      authorId: 'a1',
      body: body,
      createdAt: DateTime(2026, 7, 1, 9, 5),
    );

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

MainAxisAlignment _rowAlign(WidgetTester tester) {
  final Row row = tester.widget<Row>(find.descendant(
    of: find.byType(MessageBubble),
    matching: find.byType(Row),
  ));
  return row.mainAxisAlignment;
}

void main() {
  testWidgets('mine=true → 우측 정렬(내 메시지)', (WidgetTester tester) async {
    await tester
        .pumpWidget(_wrap(MessageBubble(message: _msg('내 메시지'), mine: true)));
    expect(find.text('내 메시지'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget); // 시각 렌더
    expect(_rowAlign(tester), MainAxisAlignment.end);
  });

  testWidgets('mine=false → 좌측 정렬(상대 메시지)', (WidgetTester tester) async {
    await tester.pumpWidget(
        _wrap(MessageBubble(message: _msg('상대 메시지'), mine: false)));
    expect(find.text('상대 메시지'), findsOneWidget);
    expect(_rowAlign(tester), MainAxisAlignment.start);
  });

  testWidgets('같은 작성자 기준이 좌우로 갈린다(거울상)', (WidgetTester tester) async {
    // 동일 메시지를 mine 만 바꿔 — 좌/우가 실제로 달라지는지.
    await tester
        .pumpWidget(_wrap(MessageBubble(message: _msg('x'), mine: true)));
    final MainAxisAlignment a = _rowAlign(tester);
    await tester
        .pumpWidget(_wrap(MessageBubble(message: _msg('x'), mine: false)));
    final MainAxisAlignment b = _rowAlign(tester);
    expect(a, isNot(equals(b)));
  });
}
