import 'dart:ui';

/// scribble Sketch JSON 의 좌표를 순수 함수로 변환/파싱하는 헬퍼(스캔 주석 전용).
///
/// ★ 좌표 정합의 핵심: 주석 스트로크는 '화면 픽셀'이 아니라 '이미지 기준 정규화
///   좌표(0..1)'로 저장한다. 저장 직전 normalize, 복원 시 denormalize —
///   변환은 InkCoordinateMapper(단일 소스)가 만든 좌표 함수를 그대로 받아 쓴다.
///
/// Sketch JSON 구조(scribble): {"lines":[{"points":[{"x","y","pressure"}],
///   "color":int,"width":double}]}. 여기서는 봉투를 해석하지 않고 좌표만 매핑한다.
class AnnotationSketch {
  AnnotationSketch._();

  /// 모든 점/선폭에 [point]·[width] 변환을 적용한 새 Sketch 맵을 만든다.
  /// (원본 맵은 건드리지 않는다 — 불변 취급.)
  static Map<String, dynamic> transform(
    Map<String, dynamic> sketch, {
    required Offset Function(Offset) point,
    required double Function(double) width,
  }) {
    final List<dynamic> lines =
        (sketch['lines'] as List<dynamic>?) ?? <dynamic>[];
    return <String, dynamic>{
      ...sketch,
      'lines': lines.map((dynamic raw) {
        final Map<String, dynamic> line =
            Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
        final List<dynamic> points =
            (line['points'] as List<dynamic>?) ?? <dynamic>[];
        line['points'] = points.map((dynamic p) {
          final Map<String, dynamic> pt =
              Map<String, dynamic>.from(p as Map<dynamic, dynamic>);
          final Offset o = point(Offset(
            (pt['x'] as num).toDouble(),
            (pt['y'] as num).toDouble(),
          ));
          pt['x'] = o.dx;
          pt['y'] = o.dy;
          return pt;
        }).toList();
        if (line['width'] != null) {
          line['width'] = width((line['width'] as num).toDouble());
        }
        return line;
      }).toList(),
    };
  }

  /// 렌더링용으로 선을 파싱한다(평탄화 합성에서 사용).
  static List<AnnotationLine> parseLines(Map<String, dynamic> sketch) {
    final List<dynamic> lines =
        (sketch['lines'] as List<dynamic>?) ?? <dynamic>[];
    return lines.map((dynamic raw) {
      final Map<String, dynamic> line =
          Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
      final List<dynamic> pts =
          (line['points'] as List<dynamic>?) ?? <dynamic>[];
      return AnnotationLine(
        points: pts
            .map((dynamic p) => Offset(
                  ((p as Map<dynamic, dynamic>)['x'] as num).toDouble(),
                  (p['y'] as num).toDouble(),
                ))
            .toList(),
        color: (line['color'] as num?)?.toInt() ?? 0xFF000000,
        width: (line['width'] as num?)?.toDouble() ?? 1.0,
      );
    }).toList();
  }
}

/// 렌더링용 선 1개(점 목록 + 색 + 선폭). 좌표 단위는 호출부 기준(정규화 or 픽셀).
class AnnotationLine {
  const AnnotationLine({
    required this.points,
    required this.color,
    required this.width,
  });

  final List<Offset> points;
  final int color;
  final double width;
}
