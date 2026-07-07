import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/scan/picked_image.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import '../../question_room/data/attachments/attachment_upload.dart'
    show validatePickedImage;
import 'individual_question_repository.dart';
import 'models/individual_question_models.dart';

/// 개별질문 첨부 업로드 포트(S17). 조회는 기존
/// [IndividualQuestionRepository.listAttachments](당사자 SELECT RLS)가 담당.
///
/// ★ 쓰기 규약: 이 DB 의 IQ 테이블은 SELECT-only — 행 등록은 반드시
///   SECURITY DEFINER RPC `add_individual_question_attachment` 로 한다
///   (supabase/migrations/20260707T0100_add_iq_attachment_rpc.sql, 적용 대기).
abstract class IqAttachmentsPort {
  /// 준비 여부(RPC 적용·버킷). false 면 upload 는 안내 에러.
  bool get isReady;

  /// 파일 업로드 + 행 등록(한 메서드 — 경로 규약을 호출부가 다룰 필요 없음).
  Future<IqAttachment> upload({
    required String questionId,
    required PickedImage image,
    String? messageId,
  });
}

/// Supabase 구현 — 버킷 업로드 → RPC 행 등록.
class SupabaseIqAttachmentsRepository implements IqAttachmentsPort {
  const SupabaseIqAttachmentsRepository();

  /// 실사 확인된 기존 버킷(웹과 공유). 신설 아님.
  static const String bucket = IndividualQuestionRepository.attachmentBucket;

  @override
  bool get isReady => true;

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  @override
  Future<IqAttachment> upload({
    required String questionId,
    required PickedImage image,
    String? messageId,
  }) async {
    final String? invalid = validatePickedImage(image);
    if (invalid != null) throw AppError(invalid);

    // 규약: 첫 세그먼트 = 질문 uuid (스토리지 RLS·RPC 위조 검증과 동일).
    final String objectPath = buildStoragePath(
      questionId: questionId,
      fileName: image.fileName,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      salt: Random().nextInt(0xFFFFFF),
    );

    await _client.storage.from(bucket).uploadBinary(
          objectPath,
          image.bytes,
          fileOptions: FileOptions(contentType: image.mimeType, upsert: false),
        );

    // 행 등록은 RPC 만(테이블 INSERT 정책 없음 — SELECT-only 규약).
    final dynamic id = await _client.rpc<dynamic>(
      'add_individual_question_attachment',
      params: <String, dynamic>{
        'p_question_id': questionId,
        'p_storage_path': objectPath,
        'p_file_name': image.fileName,
        'p_mime_type': image.mimeType,
        if (messageId != null) 'p_message_id': messageId,
      },
    );

    return IqAttachment(
      id: id as String,
      storagePath: objectPath,
      messageId: messageId,
      fileName: image.fileName,
      mimeType: image.mimeType,
    );
  }

  /// 경로 조립(순수 함수 — 테스트 가능):
  /// '{questionId}/{ts}-{salt}.{ext}' — 첫 세그먼트 = 질문 uuid 규약,
  /// ts+salt 로 파일명 충돌 방지(별도 uuid 의존성 없이).
  static String buildStoragePath({
    required String questionId,
    required String fileName,
    required int timestamp,
    required int salt,
  }) {
    final int dot = fileName.lastIndexOf('.');
    final String ext = dot <= 0
        ? 'bin'
        : fileName
            .substring(dot + 1)
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final String saltHex = salt.toRadixString(16).padLeft(6, '0');
    return '$questionId/$timestamp-$saltHex.${ext.isEmpty ? 'bin' : ext}';
  }
}
