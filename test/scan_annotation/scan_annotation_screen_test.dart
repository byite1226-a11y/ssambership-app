import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:ssambership_app/core/ink/ink_document.dart';
import 'package:ssambership_app/features/question_room/data/attachments/attachment_upload.dart';
import 'package:ssambership_app/features/question_room/data/models/question_attachment.dart';
import 'package:ssambership_app/core/ink/widgets/ink_toolbar.dart';
import 'package:ssambership_app/features/scan_annotation/data/scan_annotation_repository.dart';
import 'package:ssambership_app/features/scan_annotation/scan_annotation_screen.dart';

/// 미사용 포트(레포가 상위 메서드를 override 하므로 호출되지 않음).
class _NullDocStore implements AnnotationDocStore {
  const _NullDocStore();
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NullUploader implements AttachmentUploaderPort {
  const _NullUploader();
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 전송 여부만 기록하는 가짜 레포.
class _FakeRepo extends ScanAnnotationRepository {
  _FakeRepo()
      : super(docStore: const _NullDocStore(), uploader: const _NullUploader());

  int submitCount = 0;

  @override
  Future<QuestionAttachment> submit({
    required String roomId,
    required String threadId,
    required InkDocument document,
    required Uint8List flattenedPng,
    String fileName = 'annotation.png',
  }) async {
    submitCount++;
    return QuestionAttachment(
      id: 'att-1',
      threadId: threadId,
      storagePath: 'x',
      createdAt: DateTime(2026, 7, 1),
    );
  }
}

Future<ui.Image> _solidImage(int w, int h) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFFEEEEEE),
  );
  return recorder.endRecording().toImage(w, h);
}

Widget _app(Widget home) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: home,
    );

void main() {
  testWidgets('스모크: 배경·주석 캔버스·툴바·완료가 렌더된다',
      (WidgetTester tester) async {
    late ui.Image bg;
    await tester.runAsync(() async => bg = await _solidImage(40, 20));

    await tester.pumpWidget(_app(ScanAnnotationScreen(
      background: Uint8List(0),
      roomId: 'room-1',
      threadId: 'thread-1',
      repository: _FakeRepo(),
      backgroundImageOverride: bg,
    )));
    await tester.pumpAndSettle();

    expect(find.text('사진에 주석 달기'), findsOneWidget);
    expect(find.byType(Scribble), findsOneWidget);
    expect(find.byType(InkToolbar), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets('빈 주석으로 완료 시 전송 없이 닫힌다(결과 null)',
      (WidgetTester tester) async {
    late ui.Image bg;
    await tester.runAsync(() async => bg = await _solidImage(40, 20));
    final _FakeRepo repo = _FakeRepo();
    Object? captured;
    bool returned = false;

    await tester.pumpWidget(_app(Scaffold(
      body: Builder(
        builder: (BuildContext context) => ElevatedButton(
          onPressed: () async {
            captured = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => ScanAnnotationScreen(
                  background: Uint8List(0),
                  roomId: 'room-1',
                  threadId: 'thread-1',
                  repository: repo,
                  backgroundImageOverride: bg,
                ),
              ),
            );
            returned = true;
          },
          child: const Text('열기'),
        ),
      ),
    )));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(captured, isNull); // 빈 주석 → 전송 없음
    expect(repo.submitCount, 0);
  });
}
