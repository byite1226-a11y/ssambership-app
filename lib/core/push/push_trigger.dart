import 'edge_function_push_sender.dart';
import 'push_payload.dart';
import 'push_ports.dart';

/// 푸시 '발송 트리거 지점'. 답변 등록·신규 질문 등 이벤트에서 호출한다.
///
/// ★ 실제 발송은 서버(Edge Function). 여기서는 이벤트 → payload 생성 후 sender 포트로 넘긴다.
///   sender 미배포면([isReady]=false) 조용히 건너뛴다(호출 지점만 준비 — 인수인계).
///   ★ 연결(인수인계): question_room 의 '답변 전송'·'새 질문 생성' 성공 직후 아래 메서드를 호출.
class PushTrigger {
  const PushTrigger({PushSenderPort sender = const EdgeFunctionPushSender()})
      : _sender = sender;

  final PushSenderPort _sender;

  /// 멘토가 답변을 등록 → 학생에게.
  Future<void> onMentorAnswered({
    required String studentUserId,
    required String threadId,
    String? threadTitle,
  }) {
    return _send(
      PushPayloadBuilder.questionAnswered(
          threadId: threadId, threadTitle: threadTitle),
      studentUserId,
    );
  }

  /// 학생이 새 질문/메시지 → 멘토에게.
  Future<void> onNewQuestionForMentor({
    required String mentorUserId,
    required String threadId,
    String? threadTitle,
  }) {
    return _send(
      PushPayloadBuilder.questionMessageReceived(
          threadId: threadId, threadTitle: threadTitle, toMentor: true),
      mentorUserId,
    );
  }

  /// 멘토가 새 메시지 → 학생에게.
  Future<void> onNewMessageForStudent({
    required String studentUserId,
    required String threadId,
    String? threadTitle,
  }) {
    return _send(
      PushPayloadBuilder.questionMessageReceived(
          threadId: threadId, threadTitle: threadTitle, toMentor: false),
      studentUserId,
    );
  }

  Future<void> _send(PushPayload payload, String toUserId) async {
    if (!_sender.isReady) return; // 서버 미배포 → 발송 생략(트리거 지점만).
    await _sender.send(payload, toUserId: toUserId);
  }
}
