import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/ink/ink_document.dart';
import '../../../../core/ink/ink_storage_paths.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../shared/errors/app_error.dart';
import '../../data/models/connection_note.dart';
import '../ink_note_result.dart';

/// 필기 저장 계층이 백엔드에 필요로 하는 최소 동작(포트).
///
/// ★ 주입 분리: 저장/로드 로직(경로 조립·행 upsert 분기)은 [InkNoteRepository]
///   가 갖고, Supabase 구체 호출은 이 포트 뒤로 숨긴다 → 테스트는 fake 포트로
///   실DB 없이 검증한다.
abstract class InkNoteBackend {
  /// 현재 로그인 사용자 id(경로 authorId · 행 author_id). 없으면 [AppError].
  String requireUserId();

  /// 현재 사용자 역할 코드(student|mentor) — 새 노트 행 insert 시 author_role.
  String requireAuthorRoleCode();

  /// Storage 바이너리 업로드(같은 경로 덮어쓰기 = upsert).
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  /// Storage 바이너리 다운로드.
  Future<Uint8List> downloadBinary({
    required String bucket,
    required String path,
  });

  /// 비공개 버킷 표시용 서명 URL 발급.
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  });

  /// 방에서 내(=authorId) 연결노트 행 조회. 없으면 null.
  Future<Map<String, dynamic>?> findMyNoteRow({
    required String roomId,
    required String authorId,
  });

  /// connection_notes 새 행 insert 후 저장된 행 반환.
  Future<Map<String, dynamic>> insertNoteRow(Map<String, dynamic> values);

  /// connection_notes 기존 행(id) update 후 저장된 행 반환.
  Future<Map<String, dynamic>> updateNoteRow({
    required String id,
    required Map<String, dynamic> values,
  });
}

/// 연결노트 필기 저장/로드 레포지토리(S14-2).
///
/// 저장: ink.json 업로드 + thumb.png 업로드 + connection_notes 행 upsert
///       (ink_path·ink_thumb_path 만 갱신, 기존 body 는 건드리지 않는다).
/// 로드: ink_path 원본 다운로드 → InkDocument 복원. 썸네일은 서명 URL 발급.
class InkNoteRepository {
  const InkNoteRepository(this._backend);

  /// 운영 기본 구현(Supabase + AuthService).
  factory InkNoteRepository.supabase() =>
      const InkNoteRepository(SupabaseInkNoteBackend());

  final InkNoteBackend _backend;

  static const int _signedUrlTtlSeconds = 60 * 60; // 1시간

  /// 명시 저장. 저장 후 갱신된 [ConnectionNote] 반환.
  Future<ConnectionNote> save({
    required String roomId,
    required InkNoteResult result,
  }) async {
    final String authorId = _backend.requireUserId();
    final String docPath = InkStoragePaths.noteDocument(roomId, authorId);
    final Uint8List? thumb = result.thumbnailPng;
    final String? thumbPath =
        thumb == null ? null : InkStoragePaths.noteThumbnail(roomId, authorId);

    // 1) 원본 JSON 업로드(같은 경로 덮어쓰기).
    await _backend.uploadBinary(
      bucket: InkStoragePaths.bucket,
      path: docPath,
      bytes: Uint8List.fromList(utf8.encode(result.document.toJsonString())),
      contentType: 'application/json',
    );

    // 2) 썸네일이 있으면 업로드(렌더 실패 시 생략 — 원본만으로도 유효).
    if (thumb != null && thumbPath != null) {
      await _backend.uploadBinary(
        bucket: InkStoragePaths.bucket,
        path: thumbPath,
        bytes: thumb,
        contentType: 'image/png',
      );
    }

    // 3) connection_notes 행 upsert — ink 경로만 반영, body 는 보존.
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic>? existing =
        await _backend.findMyNoteRow(roomId: roomId, authorId: authorId);

    if (existing != null) {
      final Map<String, dynamic> row = await _backend.updateNoteRow(
        id: existing['id'] as String,
        values: <String, dynamic>{
          'ink_path': docPath,
          if (thumbPath != null) 'ink_thumb_path': thumbPath,
          'updated_at': nowIso,
        },
      );
      return ConnectionNote.fromMap(row);
    }

    final Map<String, dynamic> row =
        await _backend.insertNoteRow(<String, dynamic>{
      'mentor_student_room_id': roomId,
      'author_id': authorId,
      'author_role': _backend.requireAuthorRoleCode(),
      'ink_path': docPath,
      if (thumbPath != null) 'ink_thumb_path': thumbPath,
    });
    return ConnectionNote.fromMap(row);
  }

  /// 필기 원본을 내려받아 [InkDocument] 로 복원(재편집 진입용).
  /// ink_path 가 없으면 [AppError].
  Future<InkDocument> loadDocument(ConnectionNote note) async {
    final String? path = note.inkPath;
    if (path == null || path.isEmpty) {
      throw const AppError('불러올 필기가 없어요.');
    }
    final Uint8List bytes = await _backend.downloadBinary(
      bucket: InkStoragePaths.bucket,
      path: path,
    );
    return InkDocument.fromJsonString(utf8.decode(bytes));
  }

  /// 목록 카드용 썸네일 서명 URL. 썸네일이 없으면 null.
  Future<String?> thumbnailUrl(ConnectionNote note) async {
    final String? path = note.inkThumbPath;
    if (path == null || path.isEmpty) return null;
    return _backend.createSignedUrl(
      bucket: InkStoragePaths.bucket,
      path: path,
      expiresInSeconds: _signedUrlTtlSeconds,
    );
  }
}

/// Supabase + AuthService 백엔드 구현(운영 경로).
class SupabaseInkNoteBackend implements InkNoteBackend {
  const SupabaseInkNoteBackend();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  @override
  String requireUserId() {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) throw const AppError('로그인이 필요해요.');
    return id;
  }

  @override
  String requireAuthorRoleCode() {
    switch (AuthService.instance.currentRole) {
      case AppRole.student:
        return 'student';
      case AppRole.mentor:
        return 'mentor';
      case AppRole.admin:
      case AppRole.guest:
        throw const AppError('이 계정은 연결노트를 작성할 수 없어요.');
    }
  }

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
  }

  @override
  Future<Uint8List> downloadBinary({
    required String bucket,
    required String path,
  }) =>
      _client.storage.from(bucket).download(path);

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) =>
      _client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);

  @override
  Future<Map<String, dynamic>?> findMyNoteRow({
    required String roomId,
    required String authorId,
  }) =>
      _client
          .from('connection_notes')
          .select('*')
          .eq('mentor_student_room_id', roomId)
          .eq('author_id', authorId)
          .maybeSingle();

  @override
  Future<Map<String, dynamic>> insertNoteRow(Map<String, dynamic> values) =>
      _client.from('connection_notes').insert(values).select().single();

  @override
  Future<Map<String, dynamic>> updateNoteRow({
    required String id,
    required Map<String, dynamic> values,
  }) =>
      _client
          .from('connection_notes')
          .update(values)
          .eq('id', id)
          .select()
          .single();
}
