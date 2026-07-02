import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/scan_annotation/annotation_flattener.dart';

/// 단색 배경 이미지 생성(테스트용).
Future<ui.Image> _solidImage(int w, int h) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(w, h);
}

void main() {
  testWidgets('flatten: 배경 원본 해상도의 비어있지 않은 PNG 생성',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final ui.Image bg = await _solidImage(20, 10);
      final Map<String, dynamic> sketch = <String, dynamic>{
        'lines': <dynamic>[
          <String, dynamic>{
            'points': <dynamic>[
              <String, dynamic>{'x': 0.1, 'y': 0.1, 'pressure': 0.5},
              <String, dynamic>{'x': 0.9, 'y': 0.9, 'pressure': 0.5},
            ],
            'color': 0xFFFF0000,
            'width': 0.05,
          },
        ],
      };

      final png = await AnnotationFlattener.flatten(
        background: bg,
        normalizedSketch: sketch,
      );
      expect(png, isNotEmpty);

      // 출력은 배경 원본 해상도(20x10)여야 한다.
      final ui.Image out = await AnnotationFlattener.decodeImage(png);
      expect(out.width, 20);
      expect(out.height, 10);
    });
  });

  testWidgets('flatten: 스트로크 없어도 배경만으로 PNG 생성',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final ui.Image bg = await _solidImage(8, 8);
      final png = await AnnotationFlattener.flatten(
        background: bg,
        normalizedSketch: <String, dynamic>{'lines': <dynamic>[]},
      );
      expect(png, isNotEmpty);
    });
  });
}
