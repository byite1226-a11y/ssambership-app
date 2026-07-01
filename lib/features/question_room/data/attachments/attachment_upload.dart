import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../shared/errors/app_error.dart';
import '../models/question_attachment.dart';

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

/// 선택된 이미지(메모리). 실제 파일 선택기(image_picker)는 아직 미도입 → 주입 포트로 분리.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get sizeBytes => bytes.length;
}

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
    required String threadId,
    String? messageId,
    required PickedImage image,
  });
}

/// Supabase Storage 업로드 구현.
///
/// ★ 인프라 의존(인수인계): 아래 [bucket] 이름의 Storage 버킷과 '방 참여자만 read/write'
///   정책이 있어야 한다. 현재 로컬 확인 결과 버킷이 없어서 [_storageReady]=false 로 둔다.
///   버킷 생성은 이 작업 범위 밖(인프라 생성 금지). 준비되면 플래그만 켜면 동작한다.
///   업로드 로직(uploadBinary + question_attachments insert)은 아래에 완성해 둔다.
class SupabaseAttachmentUploader implements AttachmentUploaderPort {
  const SupabaseAttachmentUploader();

  /// TODO(인수인계): 실제 버킷명 확정. 웹과 공유하는 첨부 버킷명으로 맞출 것.
  static const String bucket = 'question-attachments';

  /// ★ 버킷 미확인 → 비활성. 오너/동업자가 버킷+정책을 만들면 true 로 전환.
  static const bool _storageReady = false;

  @override
  bool get isReady => _storageReady;

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  @override
  Future<QuestionAttachment> upload({
    required String threadId,
    String? messageId,
    required PickedImage image,
  }) async {
    final String? invalid = validatePickedImage(image);
    if (invalid != null) throw AppError(invalid);

    if (!_storageReady) {
      // 버킷 미준비 → 저장 보류(골격). 화면은 이 에러를 사용자 안내로 표시한다.
      throw const AppError('이미지 첨부 저장소가 아직 준비되지 않았어요. (저장소 설정 인수인계)');
    }

    // --- 아래는 버킷 준비 시 그대로 동작하는 실제 업로드 경로(인수인계 검토용) ---
    final String safeName = image.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final String objectPath =
        '$threadId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

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
}
