import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/ui/widgets/entrance_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('EntranceCard: 제목·child·trailing 렌더 + 탭 콜백',
      (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(_wrap(
      EntranceCard(
        icon: Icons.forum_outlined,
        title: '질문 / 답변',
        trailing: const Text('답변 대기 2'),
        onTap: () => taps++,
        child: const Text('최근 질문 미리보기'),
      ),
    ));
    expect(find.text('질문 / 답변'), findsOneWidget);
    expect(find.text('답변 대기 2'), findsOneWidget);
    expect(find.text('최근 질문 미리보기'), findsOneWidget);

    await tester.tap(find.text('질문 / 답변'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('방 홈의 두 입구(질문/답변 · 연결노트)가 함께 존재',
      (WidgetTester tester) async {
    // 학생/멘토 방 홈의 핵심 구조 — 동등한 두 입구.
    await tester.pumpWidget(_wrap(
      ListView(
        children: <Widget>[
          EntranceCard(
            icon: Icons.forum_outlined,
            title: '질문 / 답변',
            onTap: () {},
            child: const Text('미리보기'),
          ),
          EntranceCard(
            icon: Icons.sticky_note_2_outlined,
            title: '연결노트',
            onTap: () {},
            child: const Text('내 노트 추가'),
          ),
        ],
      ),
    ));
    expect(find.text('질문 / 답변'), findsOneWidget);
    expect(find.text('연결노트'), findsOneWidget);
  });
}
