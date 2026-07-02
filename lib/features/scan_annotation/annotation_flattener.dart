import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'annotation_sketch.dart';

/// 배경 이미지 + 정규화 주석 스트로크 → '원본 해상도' 평탄화 PNG 합성기.
///
/// ★ 오프스크린 합성: 화면 RepaintBoundary(위젯 렌더)에 의존하지 않고 dart:ui
///   Canvas 로 직접 그린다 → 화면이 없어도 동작하고 테스트하기 좋다.
/// ★ 해상도 기준: 출력은 배경 원본 픽셀 크기. 정규화 좌표(0..1)를 이미지 픽셀로
///   되돌려 그리므로 기기·줌과 무관하게 첨삭 위치가 보존된다.
class AnnotationFlattener {
  AnnotationFlattener._();

  /// [background] 위에 [normalizedSketch](0..1 좌표)를 얹어 PNG 바이트를 만든다.
  static Future<Uint8List> flatten({
    required ui.Image background,
    required Map<String, dynamic> normalizedSketch,
  }) async {
    final int w = background.width;
    final int h = background.height;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );

    // 1) 배경(원본 해상도 그대로).
    canvas.drawImage(background, Offset.zero, Paint());

    // 2) 정규화 스트로크 → 이미지 픽셀로 스케일해서 그린다.
    for (final AnnotationLine line in AnnotationSketch.parseLines(normalizedSketch)) {
      if (line.points.isEmpty) continue;
      final Paint paint = Paint()
        ..color = Color(line.color)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (line.width * w).clamp(1.0, w.toDouble());

      final Path path = Path();
      final Offset first = _toPixel(line.points.first, w, h);
      path.moveTo(first.dx, first.dy);
      if (line.points.length == 1) {
        // 점 하나면 짧은 선으로 보이도록 살짝 이동.
        path.lineTo(first.dx + 0.1, first.dy + 0.1);
      } else {
        for (int i = 1; i < line.points.length; i++) {
          final Offset p = _toPixel(line.points[i], w, h);
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image out = await picture.toImage(w, h);
    try {
      final ByteData? data =
          await out.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('평탄화 PNG 인코딩에 실패했어요.');
      }
      return data.buffer.asUint8List();
    } finally {
      out.dispose();
      picture.dispose();
    }
  }

  static Offset _toPixel(Offset normalized, int w, int h) =>
      Offset(normalized.dx * w, normalized.dy * h);

  /// PNG/JPEG 바이트 → dart:ui 이미지(배경 소스 디코딩용).
  static Future<ui.Image> decodeImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }
}
