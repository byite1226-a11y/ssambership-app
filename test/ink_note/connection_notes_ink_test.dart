import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:ssambership_app/core/ink/ink_document.dart';
import 'package:ssambership_app/core/ink/ink_input_mode.dart';
import 'package:ssambership_app/features/question_room/data/models/connection_note.dart';
import 'package:ssambership_app/features/question_room/data/models/room.dart';
import 'package:ssambership_app/features/question_room/ink_note/data/ink_note_repository.dart';
import 'package:ssambership_app/features/question_room/ink_note/ink_note_result.dart';
import 'package:ssambership_app/features/question_room/ink_note/ink_note_screen.dart';
import 'package:ssambership_app/features/question_room/ui/connection_notes_screen.dart';
import 'package:ssambership_app/shared/errors/app_error.dart';

/// 저장 계층을 실제로 부르지 않는 백엔드(포트) — _FakeInkRepo 가 상위 메서드를
/// 전부 override 하므로 호출되지 않는다.
class _UnusedBackend implements InkNoteBackend {
  const _UnusedBackend();
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 화면 흐름 검증용 가짜 저장 레포. 네트워크·실DB 미접촉.
class _FakeInkRepo extends InkNoteRepository {
  _FakeInkRepo({this.loadResult, this.saveThrows = false})
      : super(const _UnusedBackend());

  final InkDocument? loadResult;
  final bool saveThrows;

  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<ConnectionNote> save({
    required String roomId,
    required InkNoteResult result,
  }) async {
    saveCount++;
    if (saveThrows) throw const AppError('업로드 실패');
    return ConnectionNote(
      id: 'saved',
      roomId: roomId,
      authorRole: NoteAuthorRole.student,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      inkPath: 'room-1/m1/ink.json',
      inkThumbPath: 'room-1/m1/thumb.png',
    );
  }

  @override
  Future<InkDocument> loadDocument(ConnectionNote note) async {
    loadCount++;
    return loadResult ??
        InkDocument(
          canvasWidth: 400,
          canvasHeight: 800,
          sketch: _sketchJson(),
          inputMode: InkInputMode.penOnly,
        );
  }

  @override
  Future<String?> thumbnailUrl(ConnectionNote note) async =>
      null; // 테스트: Image.network 회피(경로 유무만으로 썸네일 표시).
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

InkDocument _nonEmptyDoc() => InkDocument(
      canvasWidth: 400,
      canvasHeight: 800,
      sketch: _sketchJson(),
      inputMode: InkInputMode.penOnly,
    );

Room _room() => Room(
      id: 'room-1',
      studentId: 's1',
      mentorId: 'm1',
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

ConnectionNote _myInkNote() => ConnectionNote(
      id: 'n1',
      roomId: 'room-1',
      authorId: 'm1',
      authorRole: NoteAuthorRole.mentor,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      inkPath: 'room-1/m1/ink.json',
      inkThumbPath: 'room-1/m1/thumb.png',
    );

/// NoSplash: 헤드리스 테스트에서 ink_sparkle 셰이더 로딩을 피한다.
Widget _app(Widget home) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: home,
    );

void main() {
  testWidgets('썸네일 존재 시: 탭하면 로드 후 재편집 화면으로 진입',
      (WidgetTester tester) async {
    final _FakeInkRepo repo = _FakeInkRepo(loadResult: _nonEmptyDoc());
    await tester.pumpWidget(_app(ConnectionNotesScreen(
      room: _room(),
      mentorName: '김멘토',
      currentUserId: 'm1',
      inkRepository: repo,
      notesLoader: () async => <ConnectionNote>[_myInkNote()],
    )));
    await tester.pumpAndSettle();

    // 내 노트에 필기가 있으니 썸네일 미리보기가 보인다.
    final Finder thumb =
        find.bySemanticsLabel('내 필기 미리보기 — 눌러서 이어 그리기');
    expect(thumb, findsOneWidget);

    await tester.tap(thumb);
    await tester.pumpAndSettle();

    expect(repo.loadCount, 1); // 원본 로드됨
    expect(find.byType(InkNoteScreen), findsOneWidget); // 재편집 진입
  });

  testWidgets('저장 성공 시 성공 스낵바 노출', (WidgetTester tester) async {
    final _FakeInkRepo repo = _FakeInkRepo(loadResult: _nonEmptyDoc());
    // 편집기 주입: RepaintBoundary 렌더 없이 완료 결과만 돌려준다.
    await tester.pumpWidget(_app(ConnectionNotesScreen(
      room: _room(),
      mentorName: '김멘토',
      currentUserId: 'm1',
      inkRepository: repo,
      notesLoader: () async => <ConnectionNote>[_myInkNote()],
      inkEditor: (InkDocument? initial) async =>
          InkNoteResult(document: _nonEmptyDoc(), modified: true),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('필기 이어 그리기'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 1);
    expect(find.text('필기를 저장했어요.'), findsOneWidget);
  });

  testWidgets('저장 실패 시 오류 스낵바 노출(앱은 유지)', (WidgetTester tester) async {
    final _FakeInkRepo repo = _FakeInkRepo(saveThrows: true);
    await tester.pumpWidget(_app(ConnectionNotesScreen(
      room: _room(),
      mentorName: '김멘토',
      currentUserId: 'm1',
      inkRepository: repo,
      notesLoader: () async => <ConnectionNote>[_myInkNote()],
      inkEditor: (InkDocument? initial) async =>
          InkNoteResult(document: _nonEmptyDoc(), modified: true),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('필기 이어 그리기'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 1);
    expect(find.textContaining('필기 저장에 실패했어요'), findsOneWidget);
  });
}
