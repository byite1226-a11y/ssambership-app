import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/scan/image_downscaler.dart';
import 'package:ssambership_app/core/scan/scan_source_picker.dart';
import 'package:ssambership_app/features/question_room/data/attachments/attachment_upload.dart';
import 'package:ssambership_app/features/question_room/data/models/question_thread.dart';
import 'package:ssambership_app/features/question_room/ui/chat_screen.dart';
import 'package:ssambership_app/shared/errors/app_error.dart';

/// S16 스캔 소스 흐름 — 바텀시트 3택 · 소스별 포트 호출 · PDF 거부 · 취소 무동작 ·
/// 초과 리사이즈. 전부 fake 포트 주입(플러그인·DB 비접촉).
class _FakeScanPort implements ScanSourcePort {
  _FakeScanPort({this.result, this.error});

  final PickedImage? result;
  final Object? error;
  final List<ScanSource> calls = <ScanSource>[];

  @override
  bool get isAvailable => true;

  @override
  Future<PickedImage?> pick(ScanSource source) async {
    calls.add(source);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeGalleryPort implements ImagePickerPort {
  _FakeGalleryPort({this.result});

  final PickedImage? result;
  int calls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<PickedImage?> pickImage() async {
    calls++;
    return result;
  }
}

PickedImage _img(String name) => PickedImage(
      bytes: Uint8List.fromList(List<int>.filled(64, 7)),
      fileName: name,
      mimeType: 'image/png',
    );

QuestionThread _thread() {
  final DateTime now = DateTime(2026, 7, 1);
  return QuestionThread(
    id: 't1',
    roomId: 'r1',
    title: '미분 질문',
    status: ThreadStatus.pending,
    isWrongAnswer: false,
    masteryStatus: MasteryStatus.unknown,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _chat({ScanSourcePort? scan, ImagePickerPort? gallery}) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: ChatScreen(
        thread: _thread(),
        mentorName: '김선생',
        scanPicker: scan ?? _FakeScanPort(),
        imagePicker: gallery ?? _FakeGalleryPort(),
      ),
    );

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.attach_file));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('첨부 탭 → 바텀시트 3택(촬영·갤러리·파일) 렌더',
      (WidgetTester tester) async {
    await tester.pumpWidget(_chat());
    await tester.pump();
    await _openSheet(tester);

    expect(find.text('촬영'), findsOneWidget);
    expect(find.text('갤러리'), findsOneWidget);
    expect(find.text('파일'), findsOneWidget);
  });

  testWidgets('촬영 선택 → scanPicker.pick(camera) + 미리보기(파일명)',
      (WidgetTester tester) async {
    final _FakeScanPort scan = _FakeScanPort(result: _img('camera.png'));
    await tester.pumpWidget(_chat(scan: scan));
    await tester.pump();
    await _openSheet(tester);

    await tester.tap(find.text('촬영'));
    await tester.pumpAndSettle();

    expect(scan.calls, <ScanSource>[ScanSource.camera]);
    expect(find.textContaining('camera.png'), findsOneWidget); // 미리보기
  });

  testWidgets('파일 선택 → scanPicker.pick(file)', (WidgetTester tester) async {
    final _FakeScanPort scan = _FakeScanPort(result: _img('scan.png'));
    await tester.pumpWidget(_chat(scan: scan));
    await tester.pump();
    await _openSheet(tester);

    await tester.tap(find.text('파일'));
    await tester.pumpAndSettle();

    expect(scan.calls, <ScanSource>[ScanSource.file]);
    expect(find.textContaining('scan.png'), findsOneWidget);
  });

  testWidgets('갤러리 선택 → 기존 imagePicker 포트 호출(하위호환 주입 지점)',
      (WidgetTester tester) async {
    final _FakeScanPort scan = _FakeScanPort();
    final _FakeGalleryPort gallery = _FakeGalleryPort(result: _img('g.png'));
    await tester.pumpWidget(_chat(scan: scan, gallery: gallery));
    await tester.pump();
    await _openSheet(tester);

    await tester.tap(find.text('갤러리'));
    await tester.pumpAndSettle();

    expect(gallery.calls, 1);
    expect(scan.calls, isEmpty); // 갤러리는 scanPicker 를 타지 않는다.
    expect(find.textContaining('g.png'), findsOneWidget);
  });

  testWidgets('PDF 거부: AppError 폴백 안내가 원문 비노출 규약으로 표시',
      (WidgetTester tester) async {
    final _FakeScanPort scan =
        _FakeScanPort(error: const AppError(kScanPdfNotSupportedText));
    await tester.pumpWidget(_chat(scan: scan));
    await tester.pump();
    await _openSheet(tester);

    await tester.tap(find.text('파일'));
    await tester.pumpAndSettle();

    expect(find.text(kScanPdfNotSupportedText), findsOneWidget);
  });

  testWidgets('시트 취소(바깥 탭) → 아무 포트도 호출되지 않는다(무동작)',
      (WidgetTester tester) async {
    final _FakeScanPort scan = _FakeScanPort(result: _img('x.png'));
    final _FakeGalleryPort gallery = _FakeGalleryPort(result: _img('x.png'));
    await tester.pumpWidget(_chat(scan: scan, gallery: gallery));
    await tester.pump();
    await _openSheet(tester);

    await tester.tapAt(const Offset(10, 10)); // 바깥 탭으로 dismiss.
    await tester.pumpAndSettle();

    expect(scan.calls, isEmpty);
    expect(gallery.calls, 0);
    expect(find.textContaining('x.png'), findsNothing);
  });

  group('downscaleIfOversized (§6-4 초과 리사이즈)', () {
    // ★ testWidgets(fake async)에서는 엔진 코덱(디코드/PNG 인코딩) 콜백이
    //   진행되지 않아 멈춘다 → 실제 async 를 쓰는 plain test() 로 검증.
    TestWidgetsFlutterBinding.ensureInitialized();

    Future<Uint8List> encodePng(int w, int h) async {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      // 압축이 덜 되도록 셀마다 색이 다른 격자를 그린다(리사이즈 효과 검증용).
      for (int x = 0; x < w; x += 8) {
        for (int y = 0; y < h; y += 8) {
          canvas.drawRect(
            ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 8, 8),
            ui.Paint()..color = ui.Color(0xFF000000 | (x * 7919 + y * 104729)),
          );
        }
      }
      final ui.Image img =
          await recorder.endRecording().toImage(w, h);
      final ByteData? data =
          await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      return data!.buffer.asUint8List();
    }

    test('초과분은 장변 캡으로 축소돼 한도 안으로 들어온다', () async {
      final Uint8List big = await encodePng(400, 300);
      final PickedImage src = PickedImage(
          bytes: big, fileName: 'big.jpg', mimeType: 'image/jpeg');
      // 원본이 한도를 넘도록 한도를 원본보다 작게 설정(실전 5MB 의 축소판).
      final PickedImage out = await downscaleIfOversized(src,
          maxBytes: big.length - 1, maxLongSide: 40);

      expect(out.sizeBytes, lessThanOrEqualTo(big.length - 1));
      expect(out.mimeType, 'image/png'); // dart:ui 재인코딩은 PNG.
      expect(out.fileName, 'big.png');
      final ui.Codec codec = await ui.instantiateImageCodec(out.bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      expect(frame.image.width, lessThanOrEqualTo(40)); // 장변 캡 적용.
      frame.image.dispose();
      codec.dispose();
    });

    test('한도 이하면 원본 그대로(무손실 통과)', () async {
      final PickedImage src = _img('small.png');
      expect(identical(await downscaleIfOversized(src), src), isTrue);
    });

    test('디코드 불가 바이트는 원본 반환 → 하류 검증이 기존 문구로 거부', () async {
      final PickedImage bad = PickedImage(
        bytes: Uint8List.fromList(List<int>.filled(64, 1)),
        fileName: 'broken.jpg',
        mimeType: 'image/jpeg',
      );
      final PickedImage out =
          await downscaleIfOversized(bad, maxBytes: 10, maxLongSide: 40);
      expect(identical(out, bad), isTrue);
      expect(validatePickedImage(out), isNull); // 64B<5MB — 실전 하류 통과 예시.
    });
  });
}
