import 'dart:convert';

import 'ink_input_mode.dart';

/// 잉크 문서 봉투 — Storage 에 저장되는 필기 원본(JSON)의 최상위 구조.
///
/// ★ 벡터 우선: 필기는 래스터가 아니라 스트로크 JSON 으로 저장한다.
/// ★ 라이브러리 중립: scribble 의 Sketch JSON 을 '불투명한 맵'으로 감싼다.
///   추후 perfect_freehand 계열로 교체해도 봉투(version·meta)는 유지된다.
///
/// 저장 포맷(v1):
/// {
///   "format": "ssambership.ink",
///   "version": 1,
///   "engine": "scribble",
///   "canvas": {"width": 800.0, "height": 1200.0},
///   "input_mode": "pen_only",
///   "updated_at": "2026-07-02T09:00:00Z",
///   "sketch": { ...scribble Sketch JSON... }
/// }
class InkDocument {
  const InkDocument({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.sketch,
    this.engine = defaultEngine,
    this.inputMode = InkInputMode.penOnly,
    this.updatedAt,
  });

  /// 포맷 식별자(파일이 우리 잉크 문서인지 판별).
  static const String formatId = 'ssambership.ink';

  /// 현재 봉투 버전. 구조 변경 시 증가시키고 fromJson 에서 마이그레이션.
  static const int currentVersion = 1;

  /// 1차 채택 엔진(기획서 4-2 권장안).
  static const String defaultEngine = 'scribble';

  /// 필기 당시 캔버스 논리 크기 — 재편집·좌표 정합의 기준.
  final double canvasWidth;
  final double canvasHeight;

  /// 스트로크 원본(엔진 네이티브 JSON). 봉투는 내용을 해석하지 않는다.
  final Map<String, dynamic> sketch;

  /// 스트로크를 생성한 엔진 이름.
  final String engine;

  /// 저장 당시 입력 모드(복원 시 초기값으로 사용).
  final InkInputMode inputMode;

  /// 마지막 저장 시각(UTC). 동시편집 '마지막 저장 우선' 판단용(S14).
  final DateTime? updatedAt;

  /// 빈 문서(스트로크 없음) 여부. scribble Sketch 는 {"lines": [...]} 구조.
  bool get isEmpty {
    final Object? lines = sketch['lines'];
    return lines is! List || lines.isEmpty;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'format': formatId,
        'version': currentVersion,
        'engine': engine,
        'canvas': <String, dynamic>{
          'width': canvasWidth,
          'height': canvasHeight,
        },
        'input_mode': inputMode.code,
        if (updatedAt != null)
          'updated_at': updatedAt!.toUtc().toIso8601String(),
        'sketch': sketch,
      };

  String toJsonString() => jsonEncode(toJson());

  /// 역직렬화. 우리 포맷이 아니거나 깨진 파일이면 [FormatException].
  ///
  /// 알 수 없는 상위 버전은 관대하게 읽되(전방 호환), 필수 필드가 없으면 실패.
  factory InkDocument.fromJson(Map<String, dynamic> json) {
    if (json['format'] != formatId) {
      throw const FormatException('ink 문서 포맷이 아님');
    }
    final Object? canvas = json['canvas'];
    final Object? sketch = json['sketch'];
    if (canvas is! Map || sketch is! Map) {
      throw const FormatException('ink 문서 필수 필드 누락(canvas/sketch)');
    }
    final double? width = (canvas['width'] as num?)?.toDouble();
    final double? height = (canvas['height'] as num?)?.toDouble();
    if (width == null || height == null || width <= 0 || height <= 0) {
      throw const FormatException('ink 문서 canvas 크기 불량');
    }
    DateTime? updatedAt;
    final Object? rawUpdated = json['updated_at'];
    if (rawUpdated is String) {
      updatedAt = DateTime.tryParse(rawUpdated);
    }
    return InkDocument(
      canvasWidth: width,
      canvasHeight: height,
      sketch: Map<String, dynamic>.from(sketch),
      engine: json['engine'] as String? ?? defaultEngine,
      inputMode: InkInputModeLabel.fromCode(json['input_mode'] as String?),
      updatedAt: updatedAt,
    );
  }

  factory InkDocument.fromJsonString(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('ink 문서 JSON 이 객체가 아님');
    }
    return InkDocument.fromJson(decoded);
  }

  InkDocument copyWith({
    Map<String, dynamic>? sketch,
    InkInputMode? inputMode,
    DateTime? updatedAt,
  }) =>
      InkDocument(
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
        sketch: sketch ?? this.sketch,
        engine: engine,
        inputMode: inputMode ?? this.inputMode,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
