import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/scan/picked_image.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../shared/errors/app_error.dart';
import '../models/question_attachment.dart';

// PickedImage 는 S16 에서 core/scan 으로 이동 — 기존 import 경로 하위호환.
export '../../../../core/scan/picked_image.dart' show PickedImage;

/// 첨부 업로드 제한 안내(고정 문구). 기획 안전 규칙: 교재 전체 스캔/PDF 등 금지.
const String kAttachmentRestrictionText =
    '교재 전체 PDF·스캔 등 저작권 침해 자료는 올릴 수 없어요. '
    '문제 사진처럼 꼭 필요한 부분만, 이미지(JPG·PNG) 5MB 이하로 올려주세요.';

/// 허용 이미지 MIME.
const List<String> kAllowedImageMimeTypes = <String>[
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
];

/// 최대 첨부 크기(5MB).
const int kMaxAttachmentBytes = 5 * 1024 * 1024;

/// 선택 이미지 검증. 통과하면 null, 아니면 사용자에게 보여줄 한글 사유.
String? validatePickedImage(PickedImage image) {
  if (image.sizeBytes > kMaxAttachmentBytes) {
    return '이미지가 너무 커요. 5MB 이하로 올려주세요.';
  }
  if (!kAllowedImageMimeTypes.contains(image.mimeType.toLowerCase())) {
    return '이미지(JPG·PNG) 형식만 올릴 수 있어요.';
  }
  return null;
}

/// 이미지 선택 포트. 기본 구현은 '미도입'(image_picker 인수인계) — [isAvailable]=false.
abstract class ImagePickerPort {
  /// 실제 선택 가능한지(패키지·권한 준비 여부).
  bool get isAvailable;

  /// 이미지 1장 선택. 취소/미도입이면 null.
  Future<PickedImage?> pickImage();
}

/// 기본: 아직 image_picker 를 도입하지 않아 선택 불가(인수인계 항목).
class DisabledImagePicker implements ImagePickerPort {
  const DisabledImagePicker();

  @override
  bool get isAvailable => false;

  @override
  Future<PickedImage?> pickImage() async => null;
}

/// 첨부 업로드 포트. 업로드 + question_attachments 행 생성을 담당.
abstract class AttachmentUploaderPort {
  /// 준비 여부(스토리지 버킷·정책). false 면 [upload] 은 안내 에러를 던진다.
  bool get isReady;

  Future<QuestionAttachment> upload({
    required String roomId,
    required String threadId,
    String? messageId,
    required PickedImage image,
  });
}

/// Supabase Storage 업로드 구현.
///
/// ★ 인프라(실사 확인됨): Storage 버킷 [bucket] 과 정책
///   `user_is_room_party_for_qra_path` 가 존재한다. 정책은 '경로 첫 세그먼트가
///   mentor_student_rooms.id(room UUID)일 때만 insert/select 허용'이며, 버킷이
///   비어 있어 이 정의가 유일한 규약이다 → 업로드 경로 첫 세그먼트는 반드시 roomId.
class SupabaseAttachmentUploader implements AttachmentUploaderPort {
  const SupabaseAttachmentUploader();

  /// 실제 버킷명(Supabase 실사로 확인 — 웹과 공유).
  static const String bucket = 'question-room-attachments';

  /// 버킷·정책 준비 완료 → 활성.
  static const bool _storageReady = true;

  @override
  bool get isReady => _storageReady;

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  @override
  Future<QuestionAttachment> upload({
    required String roomId,
    required String threadId,
    String? messageId,
    required PickedImage image,
  }) async {
    final String? invalid = validatePickedImage(image);
    if (invalid != null) throw AppError(invalid);

    if (!_storageReady) {
      throw const AppError('이미지 첨부 저장소가 아직 준비되지 않았어요.');
    }

    // 정책 규약: 경로 첫 세그먼트 = roomId(mentor_student_rooms.id)여야 통과한다.
    final String objectPath = buildStoragePath(
      roomId: roomId,
      threadId: threadId,
      fileName: image.fileName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _client.storage.from(bucket).uploadBinary(
          objectPath,
          image.bytes,
          fileOptions: FileOptions(contentType: image.mimeType, upsert: false),
        );

    final Map<String, dynamic> row = await _client
        .from('question_attachments')
        .insert(<String, dynamic>{
          'thread_id': threadId,
          if (messageId != null) 'message_id': messageId,
          'storage_path': objectPath,
          'file_name': image.fileName,
          'mime_type': image.mimeType,
        })
        .select()
        .single();
    return QuestionAttachment.fromMap(row);
  }

  /// Storage object 경로 조립(순수 함수 — 테스트 가능).
  /// 정책상 첫 세그먼트는 roomId 여야 한다: '{roomId}/{threadId}/{ts}_{safeName}'.
  static String buildStoragePath({
    required String roomId,
    required String threadId,
    required String fileName,
    required int timestamp,
  }) {
    final String safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    return '$roomId/$threadId/${timestamp}_$safeName';
  }
}
