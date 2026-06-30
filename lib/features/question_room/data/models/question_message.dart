import 'model_parse.dart';

/// 질문방 메시지(question_messages) = 대화 한 줄.
///
/// ★ append 전용: DB에 수정/삭제 컬럼·정책이 없다.
///   이 모델에도 수정/삭제 메서드를 두지 않는다(불변).
///   타입(text/image) 컬럼 없음 — 이미지/파일은 별도 question_attachments 행.
class QuestionMessage {
  const QuestionMessage({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory QuestionMessage.fromMap(Map<String, dynamic> map) {
    return QuestionMessage(
      id: map['id'] as String,
      threadId: map['thread_id'] as String,
      authorId: map['author_id'] as String,
      body: (map['body'] as String?) ?? '',
      createdAt: parseTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'thread_id': threadId,
        'author_id': authorId,
        'body': body,
        'created_at': createdAt.toIso8601String(),
      };
}
