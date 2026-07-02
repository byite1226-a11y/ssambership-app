import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:scribble/scribble.dart';

import 'ink_document.dart';
import 'ink_input_mode.dart';

/// scribble 어댑터 — 잉크 코어에서 scribble 타입을 아는 유일한 파일.
///
/// ★ 격리 원칙: 화면(S14/S15)과 저장 계층은 InkDocument·InkInputMode 만
///   다루고, ScribbleNotifier 생성·복원·내보내기는 전부 여기로 모은다.
///   엔진 교체(perfect_freehand 계열) 시 이 파일만 갈아끼운다.
class ScribbleInkAdapter {
  ScribbleInkAdapter._();

  /// 새 필기용 notifier 생성.
  static ScribbleNotifier createNotifier({
    InkInputMode mode = InkInputMode.penOnly,
  }) {
    final ScribbleNotifier notifier = ScribbleNotifier();
    applyInputMode(notifier, mode);
    return notifier;
  }

  /// 저장된 문서에서 notifier 복원(편집 진입 시에만 호출 — 기획서 5-2).
  static ScribbleNotifier restoreNotifier(InkDocument document) {
    final ScribbleNotifier notifier = ScribbleNotifier(
      sketch: Sketch.fromJson(document.sketch),
    );
    applyInputMode(notifier, document.inputMode);
    return notifier;
  }

  /// 현재 스케치를 봉투에 담아 내보낸다(저장 직전 호출).
  static InkDocument exportDocument(
    ScribbleNotifier notifier, {
    required Size canvasSize,
    InkInputMode mode = InkInputMode.penOnly,
    DateTime? now,
  }) {
    return InkDocument(
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      sketch: notifier.currentSketch.toJson(),
      inputMode: mode,
      updatedAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  /// 입력 모드 적용 — '펜=쓰기, 손가락=이동' 팜 리젝션의 실체.
  static void applyInputMode(ScribbleNotifier notifier, InkInputMode mode) {
    switch (mode) {
      case InkInputMode.penOnly:
        notifier.setAllowedPointersMode(ScribblePointerMode.penOnly);
      case InkInputMode.penAndTouch:
        notifier.setAllowedPointersMode(ScribblePointerMode.all);
    }
  }

  /// 목록용 PNG 썸네일 바이트 생성(원본 JSON 과 분리 저장 — 기획서 5-2).
  ///
  /// 캔버스가 화면에 붙어 있어야 렌더 가능(RepaintBoundary 접근).
  static Future<Uint8List> renderThumbnailPng(
    ScribbleNotifier notifier, {
    double pixelRatio = 1.0,
  }) async {
    final ByteData data = await notifier.renderImage(pixelRatio: pixelRatio);
    return data.buffer.asUint8List();
  }
}
