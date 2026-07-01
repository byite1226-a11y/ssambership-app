import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/push/push_trigger.dart';
import 'package:ssambership_app/core/push/push_types.dart';

import 'push_fakes.dart';

/// 발송 트리거 지점 — 올바른 payload/대상 생성 + sender 미배포 시 안전 스킵.
void main() {
  test('sender 미배포(isReady=false)면 발송을 건너뛴다(트리거 지점만 준비)', () async {
    final FakeSender sender = FakeSender(ready: false);
    final PushTrigger trigger = PushTrigger(sender: sender);
    await trigger.onMentorAnswered(
        studentUserId: 'stu-1', threadId: 'th-1', threadTitle: '질문');
    expect(sender.sendCount, 0);
  });

  test('멘토 답변 → 학생에게 questionAnswered payload 발송', () async {
    final FakeSender sender = FakeSender(ready: true);
    final PushTrigger trigger = PushTrigger(sender: sender);
    await trigger.onMentorAnswered(
        studentUserId: 'stu-1', threadId: 'th-1', threadTitle: '질문');

    expect(sender.sendCount, 1);
    expect(sender.lastTo, 'stu-1'); // 대상 = 학생
    expect(sender.lastPayload!.type, PushType.questionAnswered);
    expect(sender.lastPayload!.target.threadId, 'th-1'); // 딥링크 타깃
  });

  test('신규 질문 → 멘토에게 questionMessageReceived payload 발송', () async {
    final FakeSender sender = FakeSender(ready: true);
    final PushTrigger trigger = PushTrigger(sender: sender);
    await trigger.onNewQuestionForMentor(
        mentorUserId: 'men-1', threadId: 'th-2');

    expect(sender.lastTo, 'men-1'); // 대상 = 멘토
    expect(sender.lastPayload!.type, PushType.questionMessageReceived);
    expect(sender.lastPayload!.target.threadId, 'th-2');
  });
}
