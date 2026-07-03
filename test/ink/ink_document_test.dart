import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/ink/ink_document.dart';
import 'package:ssambership_app/core/ink/ink_input_mode.dart';

/// 잉크 문서 봉투 — 직렬화 왕복·필수 필드 검증·전방 호환(DB·네트워크 미접촉).
void main() {
  Map<String, dynamic> sampleSketch() => <String, dynamic>{
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'points': <Map<String, dynamic>>[
              <String, dynamic>{'x': 0.1, 'y': 0.2, 'pressure': 0.5},
            ],
            'color': 4278190080,
            'width': 5.0,
          },
        ],
      };

  test('toJson→fromJson 왕복 시 캔버스·모드·스케치가 보존된다', () {
    final InkDocument doc = InkDocument(
      canvasWidth: 800,
      canvasHeight: 1200,
      sketch: sampleSketch(),
      inputMode: InkInputMode.penAndTouch,
      updatedAt: DateTime.utc(2026, 7, 2, 9),
    );

    final InkDocument restored = InkDocument.fromJsonString(doc.toJsonString());

    expect(restored.canvasWidth, 800);
    expect(restored.canvasHeight, 1200);
    expect(restored.inputMode, InkInputMode.penAndTouch);
    expect(restored.updatedAt, DateTime.utc(2026, 7, 2, 9));
    expect(restored.isEmpty, isFalse);
    expect((restored.sketch['lines'] as List).length, 1);
  });

  test('스트로크가 없으면 isEmpty=true', () {
    const InkDocument doc = InkDocument(
      canvasWidth: 100,
      canvasHeight: 100,
      sketch: <String, dynamic>{'lines': <Object>[]},
    );
    expect(doc.isEmpty, isTrue);
  });

  test('format 식별자가 다르면 FormatException', () {
    expect(
      () => InkDocument.fromJson(<String, dynamic>{'format': 'other'}),
      throwsFormatException,
    );
  });

  test('canvas/sketch 누락 시 FormatException', () {
    expect(
      () => InkDocument.fromJson(<String, dynamic>{
        'format': InkDocument.formatId,
        'version': 1,
      }),
      throwsFormatException,
    );
  });

  test('알 수 없는 input_mode 는 펜 전용으로 안전 복원', () {
    final InkDocument doc = InkDocument.fromJson(<String, dynamic>{
      'format': InkDocument.formatId,
      'version': 99, // 상위 버전도 필수 필드가 있으면 관대하게 읽는다
      'canvas': <String, dynamic>{'width': 10.0, 'height': 10.0},
      'input_mode': 'hologram',
      'sketch': <String, dynamic>{'lines': <Object>[]},
    });
    expect(doc.inputMode, InkInputMode.penOnly);
  });
}
