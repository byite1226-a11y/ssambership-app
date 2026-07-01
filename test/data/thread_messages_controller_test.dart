import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/models/question_message.dart';
import 'package:ssambership_app/features/question_room/data/thread_messages_controller.dart';

QuestionMessage _m(String id, {int minute = 0, String body = 'x'}) =>
    QuestionMessage(
      id: id,
      threadId: 't1',
      authorId: 'a',
      body: body,
      createdAt: DateTime(2026, 7, 1, 10, minute),
    );

void main() {
  test('add: 새 id 는 추가, 중복 id 는 무시', () {
    final ThreadMessagesController c =
        ThreadMessagesController(<QuestionMessage>[_m('1', minute: 1)]);
    expect(c.length, 1);
    expect(c.add(_m('2', minute: 2)), true);
    expect(c.length, 2);
    expect(c.add(_m('2', minute: 2)), false); // 중복 id
    expect(c.length, 2);
  });

  test('created_at 오름차순 정렬 유지', () {
    final ThreadMessagesController c = ThreadMessagesController(
      <QuestionMessage>[_m('late', minute: 5), _m('early', minute: 1)],
    );
    expect(c.items.first.id, 'early');
    expect(c.items.last.id, 'late');
    c.add(_m('mid', minute: 3));
    expect(c.items.map((QuestionMessage e) => e.id).toList(),
        <String>['early', 'mid', 'late']);
  });

  test('resetTo: 전체 교체 + 중복 제거', () {
    final ThreadMessagesController c =
        ThreadMessagesController(<QuestionMessage>[_m('1', minute: 1)]);
    c.resetTo(<QuestionMessage>[
      _m('9', minute: 9),
      _m('9', minute: 9),
      _m('8', minute: 8),
    ]);
    expect(c.items.map((QuestionMessage e) => e.id).toList(),
        <String>['8', '9']);
  });
}
