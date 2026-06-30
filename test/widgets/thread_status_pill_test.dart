import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/models/question_thread.dart';
import 'package:ssambership_app/features/question_room/ui/widgets/thread_status_pill.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('ThreadStatusPill 은 한글 라벨을 렌더한다(영문 status 비노출)',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(_wrap(const ThreadStatusPill(status: ThreadStatus.pending)));
    expect(find.text('답변 대기'), findsOneWidget);
    expect(find.text('pending'), findsNothing);

    await tester.pumpWidget(
        _wrap(const ThreadStatusPill(status: ThreadStatus.answered)));
    expect(find.text('진행 중'), findsOneWidget);
    expect(find.text('answered'), findsNothing);

    await tester.pumpWidget(
        _wrap(const ThreadStatusPill(status: ThreadStatus.confirmed)));
    expect(find.text('답변 완료'), findsOneWidget);
    expect(find.text('confirmed'), findsNothing);
  });

  test('toneFor: pending=warning, answered=info, confirmed=success', () {
    expect(ThreadStatusPill.toneFor(ThreadStatus.pending).name, 'warning');
    expect(ThreadStatusPill.toneFor(ThreadStatus.answered).name, 'info');
    expect(ThreadStatusPill.toneFor(ThreadStatus.confirmed).name, 'success');
  });
}
