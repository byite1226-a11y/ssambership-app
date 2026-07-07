import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:ssambership_app/core/ink/ink_document.dart';
import 'package:ssambership_app/features/question_room/data/attachments/attachment_upload.dart';
import 'package:ssambership_app/features/question_room/data/models/question_attachment.dart';
import 'package:ssambership_app/features/scan_annotation/annotation_target.dart';
import 'package:ssambership_app/features/scan_annotation/data/scan_annotation_repository.dart';
import 'package:ssambership_app/features/scan_annotation/scan_annotation_screen.dart';

/// S18 AnnotationTarget — 완료 결과가 올바른 대상으로 라우팅되는지.
/// 질문방(기본, S15 현행)·주입 포트(S18) 각각을 fake 로 검증한다.
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

/// 질문방 전송 인자를 기록하는 가짜 레포(기본 라우팅 검증용).
class _RecordingRepo extends ScanAnnotationRepository {
  _RecordingRepo()
      : super(docStore: const _NullDocStore(), uploader: const _NullUploader());

  String? roomId;
  String? threadId;
  Uint8List? png;

  @override
  Future<QuestionAttachment> submit({
    required String roomId,
    required String threadId,
    required InkDocument document,
    required Uint8List flattenedPng,
    String fileName = 'annotation.png',
  }) async {
    this.roomId = roomId;
    this.threadId = threadId;
    png = flattenedPng;
    return QuestionAttachment(
      id: 'att-1',
      threadId: threadId,
      storagePath: 'x',
      createdAt: DateTime(2026, 7, 1),
    );
  }
}

/// 주입 포트 fake — submit 결과만 캡처.
class _RecordingTarget implements AnnotationTarget {
  AnnotationResult? received;

  @override
  Future<void> submit(AnnotationResult result) async {
    received = result;
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

/// 캔버스에 스트로크 1개를 주입한다(제스처 시뮬레이션 없이 결정적으로).
void _injectStroke(WidgetTester tester) {
  final Scribble scribble = tester.widget(find.byType(Scribble));
  final ScribbleNotifier notifier = scribble.notifier as ScribbleNotifier;
  notifier.setSketch(
    sketch: Sketch.fromJson(<String, dynamic>{
      'lines': <Map<String, dynamic>>[
        <String, dynamic>{
          'points': <Map<String, dynamic>>[
            <String, dynamic>{'x': 5.0, 'y': 5.0, 'pressure': 0.5},
            <String, dynamic>{'x': 20.0, 'y': 10.0, 'pressure': 0.5},
          ],
          'color': 0xFF000000,
          'width': 3.0,
        },
      ],
    }),
  );
}

/// '완료'를 누르고 평탄화(실 async 엔진 호출)가 끝날 때까지 기다린다.
Future<void> _tapDoneAndFlatten(
  WidgetTester tester,
  bool Function() submitted,
) async {
  await tester.runAsync(() async {
    await tester.tap(find.text('완료'));
    for (int i = 0; i < 200 && !submitted(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('기본(포트 미주입): 완료가 질문방 레포로 전송된다 — S15 현행 유지',
      (WidgetTester tester) async {
    late ui.Image bg;
    await tester.runAsync(() async => bg = await _solidImage(40, 20));
    final _RecordingRepo repo = _RecordingRepo();

    await tester.pumpWidget(_app(ScanAnnotationScreen(
      background: Uint8List(0),
      roomId: 'room-1',
      threadId: 'thread-1',
      repository: repo,
      backgroundImageOverride: bg,
    )));
    await tester.pumpAndSettle();

    _injectStroke(tester);
    await _tapDoneAndFlatten(tester, () => repo.png != null);

    expect(repo.roomId, 'room-1');
    expect(repo.threadId, 'thread-1');
    expect(repo.png, isNotEmpty);
  });

  testWidgets('target 주입: 완료가 포트로 라우팅된다(질문방 레포 미호출)',
      (WidgetTester tester) async {
    late ui.Image bg;
    await tester.runAsync(() async => bg = await _solidImage(40, 20));
    final _RecordingTarget target = _RecordingTarget();

    await tester.pumpWidget(_app(ScanAnnotationScreen(
      background: Uint8List(0),
      target: target,
      title: '첨삭하기',
      backgroundImageOverride: bg,
    )));
    await tester.pumpAndSettle();

    expect(find.text('첨삭하기'), findsOneWidget); // 제목 옵션.

    _injectStroke(tester);
    await _tapDoneAndFlatten(tester, () => target.received != null);

    final AnnotationResult result = target.received!;
    expect(result.flattenedPng, isNotEmpty);
    expect(result.document.isEmpty, isFalse);
    // 정규화(0..1) 좌표 규약 — 캔버스 좌표가 그대로 저장되면 안 된다.
    expect(result.document.canvasWidth, 40);
    expect(result.document.canvasHeight, 20);
  });

  testWidgets('LocalAnnotationTarget: 전송 없이 결과를 보관하고 pop(true)',
      (WidgetTester tester) async {
    late ui.Image bg;
    await tester.runAsync(() async => bg = await _solidImage(40, 20));
    final LocalAnnotationTarget target = LocalAnnotationTarget();
    bool? popResult;

    await tester.pumpWidget(_app(Scaffold(
      body: Builder(
        builder: (BuildContext context) => ElevatedButton(
          onPressed: () async {
            popResult = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => ScanAnnotationScreen(
                  background: Uint8List(0),
                  target: target,
                  backgroundImageOverride: bg,
                ),
              ),
            );
          },
          child: const Text('열기'),
        ),
      ),
    )));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    _injectStroke(tester);
    await _tapDoneAndFlatten(tester, () => target.result != null);

    expect(popResult, isTrue);
    expect(target.result!.flattenedPng, isNotEmpty);
  });

  testWidgets('initialPenColor: 멘토 첨삭 진입 시 펜이 빨강으로 프리셋된다(§6-2)',
      (WidgetTester tester) async {
    late ui.Image bg;
    await tester.runAsync(() async => bg = await _solidImage(40, 20));

    await tester.pumpWidget(_app(ScanAnnotationScreen(
      background: Uint8List(0),
      target: _RecordingTarget(),
      initialPenColor: Colors.red,
      backgroundImageOverride: bg,
    )));
    await tester.pumpAndSettle();

    final Scribble scribble = tester.widget(find.byType(Scribble));
    final int? selected = scribble.notifier.value.map(
      drawing: (Drawing d) => d.selectedColor,
      erasing: (_) => null,
    );
    expect(selected, Colors.red.toARGB32());
  });
}
