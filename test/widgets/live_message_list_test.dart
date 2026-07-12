import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/models/question_message.dart';
import 'package:ssambership_app/features/question_room/data/thread_messages_controller.dart';
import 'package:ssambership_app/features/question_room/data/thread_realtime.dart';
import 'package:ssambership_app/features/question_room/ui/widgets/live_message_list.dart';

/// 실시간 포트 fake — 실제 네트워크 없이 메시지 방출을 흉내낸다.
class _FakeRealtime implements ThreadRealtimePort {
  void Function(QuestionMessage)? _onInsert;
  bool disposed = false;

  @override
  void start({
    required void Function(QuestionMessage) onMessageInsert,
    void Function()? onThreadUpdate,
    void Function()? onAttachmentInsert,
  }) {
    _onInsert = onMessageInsert;
  }

  void emit(QuestionMessage m) => _onInsert?.call(m);

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

QuestionMessage _m(String id, String body, int minute) => QuestionMessage(
      id: id,
      threadId: 't1',
      authorId: 'u2',
      body: body,
      createdAt: DateTime(2026, 7, 1, 10, minute),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('실시간 insert 콜백 → 새로고침 없이 목록에 추가(중복 무시)',
      (WidgetTester tester) async {
    final ThreadMessagesController ctrl =
        ThreadMessagesController(<QuestionMessage>[_m('1', '안녕하세요', 1)]);
    final _FakeRealtime fake = _FakeRealtime();

    await tester.pumpWidget(_wrap(LiveMessageList(
      controller: ctrl,
      realtime: fake,
      currentUid: 'u1',
    )));
    expect(find.text('안녕하세요'), findsOneWidget);
    expect(find.text('새 메시지'), findsNothing);

    fake.emit(_m('2', '새 메시지', 2));
    await tester.pump();
    expect(find.text('새 메시지'), findsOneWidget);

    // 같은 id 를 다시 방출해도 1개만(중복 무시).
    fake.emit(_m('2', '새 메시지', 2));
    await tester.pump();
    expect(find.text('새 메시지'), findsOneWidget);
  });

  testWidgets('dispose 시 realtime 구독 정리(누수 금지)',
      (WidgetTester tester) async {
    final _FakeRealtime fake = _FakeRealtime();
    await tester.pumpWidget(_wrap(LiveMessageList(
      controller: ThreadMessagesController(),
      realtime: fake,
      currentUid: 'u1',
    )));
    await tester.pumpWidget(_wrap(const SizedBox()));
    expect(fake.disposed, true);
  });

  testWidgets('빈 목록 → 힌트 표시', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(LiveMessageList(
      controller: ThreadMessagesController(),
      realtime: _FakeRealtime(),
      currentUid: 'u1',
      emptyHint: '첫 메시지를 남겨보세요.',
    )));
    expect(find.text('첫 메시지를 남겨보세요.'), findsOneWidget);
  });
}
