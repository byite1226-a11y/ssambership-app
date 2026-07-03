import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:ssambership_app/core/ink/ink_document.dart';
import 'package:ssambership_app/core/ink/ink_input_mode.dart';
import 'package:ssambership_app/features/question_room/data/models/connection_note.dart';
import 'package:ssambership_app/features/question_room/ink_note/data/ink_note_repository.dart';
import 'package:ssambership_app/features/question_room/ink_note/ink_note_result.dart';
import 'package:ssambership_app/shared/errors/app_error.dart';

/// 업로드 1건 기록.
class _Upload {
  _Upload(this.bucket, this.path, this.bytes, this.contentType);
  final String bucket;
  final String path;
  final Uint8List bytes;
  final String contentType;
}

/// 실DB 없이 저장/로드 로직만 검증하는 fake 백엔드.
class _FakeBackend implements InkNoteBackend {
  _FakeBackend({
    this.existing,
    this.downloadBytes,
    this.userId = 'author-1',
  });

  final Map<String, dynamic>? existing;
  final Uint8List? downloadBytes;
  final String userId;
  final String roleCode = 'student';

  final List<_Upload> uploads = <_Upload>[];
  Map<String, dynamic>? insertedValues;
  Map<String, dynamic>? updatedValues;
  String? updatedId;
  String? signedForPath;

  @override
  String requireUserId() => userId;

  @override
  String requireAuthorRoleCode() => roleCode;

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploads.add(_Upload(bucket, path, bytes, contentType));
  }

  @override
  Future<Uint8List> downloadBinary({
    required String bucket,
    required String path,
  }) async =>
      downloadBytes ?? Uint8List(0);

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) async {
    signedForPath = path;
    return 'signed://$path';
  }

  @override
  Future<Map<String, dynamic>?> findMyNoteRow({
    required String roomId,
    required String authorId,
  }) async =>
      existing;

  @override
  Future<Map<String, dynamic>> insertNoteRow(Map<String, dynamic> values) async {
    insertedValues = values;
    return <String, dynamic>{...values, 'id': 'new-id'};
  }

  @override
  Future<Map<String, dynamic>> updateNoteRow({
    required String id,
    required Map<String, dynamic> values,
  }) async {
    updatedId = id;
    updatedValues = values;
    // 기존 행 + 갱신값 병합(body 등 기존 필드 보존됨을 반영).
    return <String, dynamic>{...?existing, ...values, 'id': id};
  }
}

Map<String, dynamic> _sketchJson() => const Sketch(
      lines: <SketchLine>[
        SketchLine(
          points: <Point>[Point(0, 0), Point(1, 1)],
          color: 0xFF000000,
          width: 3,
        ),
      ],
    ).toJson();

InkDocument _doc() => InkDocument(
      canvasWidth: 400,
      canvasHeight: 800,
      sketch: _sketchJson(),
      inputMode: InkInputMode.penOnly,
    );

ConnectionNote _note({String? inkPath, String? inkThumbPath, String? body}) =>
    ConnectionNote(
      id: 'n1',
      roomId: 'room-1',
      body: body,
      authorId: 'author-1',
      authorRole: NoteAuthorRole.student,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      inkPath: inkPath,
      inkThumbPath: inkThumbPath,
    );

void main() {
  test('새 노트 저장: 원본·썸네일 업로드 경로와 insert 페이로드', () async {
    final _FakeBackend backend = _FakeBackend(userId: 'author-1');
    final InkNoteRepository repo = InkNoteRepository(backend);

    await repo.save(
      roomId: 'room-1',
      result: InkNoteResult(
        document: _doc(),
        modified: true,
        thumbnailPng: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );

    // 업로드 2건: ink.json + thumb.png (모두 connection-note-ink 버킷).
    expect(backend.uploads.length, 2);
    final _Upload doc = backend.uploads[0];
    final _Upload thumb = backend.uploads[1];
    expect(doc.bucket, 'connection-note-ink');
    expect(doc.path, 'room-1/author-1/ink.json'); // 첫 세그먼트=roomId
    expect(doc.contentType, 'application/json');
    expect(thumb.path, 'room-1/author-1/thumb.png');
    expect(thumb.contentType, 'image/png');

    // insert 페이로드: ink 경로 반영, body 는 건드리지 않음.
    expect(backend.insertedValues, isNotNull);
    expect(backend.insertedValues!['mentor_student_room_id'], 'room-1');
    expect(backend.insertedValues!['author_id'], 'author-1');
    expect(backend.insertedValues!['author_role'], 'student');
    expect(backend.insertedValues!['ink_path'], 'room-1/author-1/ink.json');
    expect(backend.insertedValues!['ink_thumb_path'], 'room-1/author-1/thumb.png');
    expect(backend.insertedValues!.containsKey('body'), isFalse);
  });

  test('기존 노트 있으면 update — body 는 보존(페이로드에 없음)', () async {
    final _FakeBackend backend = _FakeBackend(
      userId: 'author-1',
      existing: <String, dynamic>{
        'id': 'existing-1',
        'mentor_student_room_id': 'room-1',
        'author_id': 'author-1',
        'author_role': 'student',
        'body': '기존 텍스트 메모',
      },
    );
    final InkNoteRepository repo = InkNoteRepository(backend);

    final ConnectionNote saved = await repo.save(
      roomId: 'room-1',
      result: InkNoteResult(
        document: _doc(),
        modified: true,
        thumbnailPng: Uint8List.fromList(<int>[9]),
      ),
    );

    expect(backend.insertedValues, isNull); // insert 아님
    expect(backend.updatedId, 'existing-1');
    expect(backend.updatedValues!['ink_path'], 'room-1/author-1/ink.json');
    expect(backend.updatedValues!['ink_thumb_path'], 'room-1/author-1/thumb.png');
    expect(backend.updatedValues!.containsKey('body'), isFalse); // 보존
    expect(saved.body, '기존 텍스트 메모'); // 병합 결과에 body 유지
  });

  test('썸네일 없으면 원본만 업로드 + ink_thumb_path 미설정', () async {
    final _FakeBackend backend = _FakeBackend();
    final InkNoteRepository repo = InkNoteRepository(backend);

    await repo.save(
      roomId: 'room-1',
      result: InkNoteResult(document: _doc(), modified: true),
    );

    expect(backend.uploads.length, 1);
    expect(backend.uploads.single.path, 'room-1/author-1/ink.json');
    expect(backend.insertedValues!.containsKey('ink_thumb_path'), isFalse);
  });

  test('로드 왕복: 다운로드 JSON → InkDocument 복원', () async {
    final InkDocument original = _doc();
    final _FakeBackend backend = _FakeBackend(
      downloadBytes: Uint8List.fromList(utf8.encode(original.toJsonString())),
    );
    final InkNoteRepository repo = InkNoteRepository(backend);

    final InkDocument loaded =
        await repo.loadDocument(_note(inkPath: 'room-1/author-1/ink.json'));

    expect(loaded.canvasWidth, 400);
    expect(loaded.canvasHeight, 800);
    expect(loaded.inputMode, InkInputMode.penOnly);
    expect(loaded.isEmpty, isFalse);
  });

  test('inkPath 없는 노트 로드는 AppError', () async {
    final InkNoteRepository repo = InkNoteRepository(_FakeBackend());
    expect(
      () => repo.loadDocument(_note()),
      throwsA(isA<AppError>()),
    );
  });

  test('썸네일 URL: 경로 있으면 서명 URL, 없으면 null', () async {
    final _FakeBackend backend = _FakeBackend();
    final InkNoteRepository repo = InkNoteRepository(backend);

    final String? url = await repo
        .thumbnailUrl(_note(inkThumbPath: 'room-1/author-1/thumb.png'));
    expect(url, 'signed://room-1/author-1/thumb.png');
    expect(backend.signedForPath, 'room-1/author-1/thumb.png');

    expect(await repo.thumbnailUrl(_note()), isNull);
  });
}
