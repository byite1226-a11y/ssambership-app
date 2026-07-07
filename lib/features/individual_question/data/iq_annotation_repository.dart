import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ink/ink_document.dart';
import '../../../core/ink/ink_storage_paths.dart';
import '../../../core/scan/image_downscaler.dart';
import '../../../core/scan/picked_image.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import '../../scan_annotation/annotation_target.dart';
import 'individual_question_repository.dart';
import 'iq_attachments_repository.dart';
import 'models/individual_question_models.dart';

/// IQ 첨삭 원본(ink.json)·원본 첨부 바이트를 넣고 빼는 최소 포트(S18).
///
/// ★ 버킷은 기존 `individual-question-attachments` 하나다 — 첨삭 JSON 도
///   `{questionId}/annotations/{원본첨부id}.json` 으로 같은 버킷에 넣는다.
///   첫 세그먼트=질문 uuid 규약을 그대로 만족하므로 정책 추가가 없다.
abstract class IqAnnotationStore {
  /// 같은 경로 덮어쓰기(upsert) — 이어 그리기 저장.
  Future<void> upsertDocument({required String path, required Uint8List bytes});

  /// 첨삭 원본 다운로드. 파일이 없으면 null(새로 시작 분기).
  Future<Uint8List?> downloadDocumentOrNull({required String path});

  /// 원본 첨부(배경 이미지) 다운로드.
  Future<Uint8List> downloadAttachment({required String storagePath});
}

/// 개별질문 첨삭 레포지토리(S18).
///
/// 완료: ① 평탄화 PNG 를 '새 첨부'로 등록(S17 파이프라인 재사용 — 원본 불변,
///       기획안 §11 기본안) ② 첨삭 원본(ink.json)을 원본 첨부 id 기준 경로에
///       upsert(이어 그리기용, 첨부 행 등록 없음 — 목록에 노출되지 않는다).
class IqAnnotationRepository {
  const IqAnnotationRepository({
    required IqAnnotationStore store,
    required IqAttachmentsPort uploader,
  })  : _store = store,
        _uploader = uploader;

  /// 운영 기본 구현(기존 IQ 버킷 + S17 업로더).
  factory IqAnnotationRepository.supabase() => const IqAnnotationRepository(
        store: SupabaseIqAnnotationStore(),
        uploader: SupabaseIqAttachmentsRepository(),
      );

  final IqAnnotationStore _store;
  final IqAttachmentsPort _uploader;

  /// 멘토 첨삭 완료. 평탄화본을 새 첨부로 등록하고(원본 유지·덮어쓰기 금지),
  /// 스트로크 원본을 [sourceAttachmentId] 기준 경로에 저장한다(재편집용).
  /// p_message_id 는 null 유지 — 메시지 연동은 후속(RPC 검증 보강과 함께).
  Future<IqAttachment> submitAnnotation({
    required String questionId,
    required String sourceAttachmentId,
    required AnnotationResult result,
  }) async {
    // 평탄화 PNG 가 5MB 를 넘으면 업로드 전 축소(§6-4 규약 — S17 과 동일 경로).
    final PickedImage image = await downscaleIfOversized(PickedImage(
      bytes: result.flattenedPng,
      fileName: 'annotation.png',
      mimeType: 'image/png',
    ));

    // 1) 새 첨부 등록(업로드 + RPC 행 등록) — S17 파이프라인 재사용.
    final IqAttachment attachment =
        await _uploader.upload(questionId: questionId, image: image);

    // 2) 이어 그리기용 원본(ink.json) upsert — 테이블 행 없음(표시용 첨부 아님).
    await _store.upsertDocument(
      path: InkStoragePaths.iqAnnotationDocument(questionId, sourceAttachmentId),
      bytes: Uint8List.fromList(utf8.encode(result.document.toJsonString())),
    );
    return attachment;
  }

  /// 같은 원본에 대한 기존 첨삭 원본을 복원한다(이어 그리기 제안용).
  /// 없거나 읽을 수 없으면 null — 호출부는 '새로 시작'으로 진행한다.
  Future<InkDocument?> loadAnnotation({
    required String questionId,
    required String sourceAttachmentId,
  }) async {
    final Uint8List? bytes = await _store.downloadDocumentOrNull(
      path: InkStoragePaths.iqAnnotationDocument(questionId, sourceAttachmentId),
    );
    if (bytes == null) return null;
    try {
      return InkDocument.fromJsonString(utf8.decode(bytes));
    } on FormatException {
      return null; // 깨진 파일 → 새로 시작(완료 시 어차피 새 첨부라 안전).
    }
  }

  /// 첨삭 배경으로 쓸 원본 첨부 바이트.
  Future<Uint8List> downloadAttachment(String storagePath) =>
      _store.downloadAttachment(storagePath: storagePath);
}

/// [AnnotationTarget] 의 IQ 구현 — 완료 결과를 S18 첨삭 파이프라인으로 보낸다.
class IqAnnotationTarget implements AnnotationTarget {
  const IqAnnotationTarget({
    required this.repository,
    required this.questionId,
    required this.sourceAttachmentId,
  });

  final IqAnnotationRepository repository;
  final String questionId;

  /// 첨삭 대상 원본 첨부 id — ink.json 경로의 키(새 첨부 id 가 아니다).
  final String sourceAttachmentId;

  @override
  Future<void> submit(AnnotationResult result) async {
    await repository.submitAnnotation(
      questionId: questionId,
      sourceAttachmentId: sourceAttachmentId,
      result: result,
    );
  }
}

/// Supabase Storage(기존 IQ 첨부 버킷) 구현.
class SupabaseIqAnnotationStore implements IqAnnotationStore {
  const SupabaseIqAnnotationStore();

  static const String bucket = IndividualQuestionRepository.attachmentBucket;

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  @override
  Future<void> upsertDocument({
    required String path,
    required Uint8List bytes,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/json',
            upsert: true,
          ),
        );
  }

  @override
  Future<Uint8List?> downloadDocumentOrNull({required String path}) async {
    try {
      return await _client.storage.from(bucket).download(path);
    } on StorageException catch (e) {
      // 부재(404)만 null — 그 외(권한·네트워크)는 그대로 올려 호출부가 안내.
      if (e.statusCode == '404' || e.error == 'not_found') return null;
      rethrow;
    }
  }

  @override
  Future<Uint8List> downloadAttachment({required String storagePath}) =>
      _client.storage.from(bucket).download(storagePath);
}
