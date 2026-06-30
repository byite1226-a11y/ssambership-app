import 'model_parse.dart';

/// 질문방 첨부(question_attachments). 이미지/파일은 메시지 타입이 아니라 이 행으로.
///
/// ★ 이번(S3)엔 모델 골격만. 실제 화면/스토리지 연결은 S6.
///   message_id 는 nullable — 스레드에는 붙되 특정 메시지에 안 붙은 첨부도 가능.
class QuestionAttachment {
  const QuestionAttachment({
    required this.id,
    required this.threadId,
    this.messageId,
    required this.storagePath,
    this.fileName,
    this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String? messageId;

  /// Supabase Storage 경로(화면에 그대로 노출 금지 — S6에서 서명 URL 등으로 처리).
  final String storagePath;
  final String? fileName;
  final String? mimeType;
  final DateTime createdAt;

  factory QuestionAttachment.fromMap(Map<String, dynamic> map) {
    return QuestionAttachment(
      id: map['id'] as String,
      threadId: map['thread_id'] as String,
      messageId: map['message_id'] as String?,
      storagePath: (map['storage_path'] as String?) ?? '',
      fileName: map['file_name'] as String?,
      mimeType: map['mime_type'] as String?,
      createdAt: parseTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'thread_id': threadId,
        'message_id': messageId,
        'storage_path': storagePath,
        'file_name': fileName,
        'mime_type': mimeType,
        'created_at': createdAt.toIso8601String(),
      };
}
