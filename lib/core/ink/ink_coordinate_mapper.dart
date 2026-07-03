import 'dart:ui';

/// 정규화 좌표 변환기 — '주석은 화면 픽셀이 아니라 원본 이미지 기준 0..1
/// 정규화 좌표로 저장한다'(스캔-주석 기획서 2-2)의 구현.
///
/// ★ 정합 주의(기획서 잠금): 이미지 비율을 유지한 채 fit 시키고, 주석은
///   이미지 좌표계에 묶는다. 이 변환을 빠뜨리면 기기·줌에 따라 첨삭 위치가
///   어긋난다 — 스캔-주석 기능에서 가장 흔한 버그 지점.
///
/// 사용 흐름:
///   1) fitRect() 로 뷰포트 안에서 이미지가 실제로 그려지는 영역을 구한다
///      (BoxFit.contain 과 동일 규칙, 중앙 정렬).
///   2) 화면 좌표 → normalize() → 저장 / 저장값 → denormalize() → 화면.
///   3) InteractiveViewer 줌·팬은 위젯 트리 변환으로 처리되므로, 캔버스가
///      이미지와 같은 레이어에 있으면 추가 보정이 필요 없다(S15 에서 검증).
class InkCoordinateMapper {
  const InkCoordinateMapper._(this.fitted);

  /// 뷰포트 안에서 이미지가 그려지는 영역(비율 유지·중앙 정렬).
  final Rect fitted;

  /// [imageSize] 원본 이미지를 [viewport] 안에 contain-fit 했을 때의 매퍼 생성.
  ///
  /// 크기가 0 이하면 [ArgumentError] — 호출부 버그를 조용히 넘기지 않는다.
  factory InkCoordinateMapper.contain({
    required Size imageSize,
    required Size viewport,
  }) {
    if (imageSize.width <= 0 ||
        imageSize.height <= 0 ||
        viewport.width <= 0 ||
        viewport.height <= 0) {
      throw ArgumentError('imageSize/viewport 는 양수여야 함: '
          'image=$imageSize viewport=$viewport');
    }
    final double scale = _containScale(imageSize, viewport);
    final double w = imageSize.width * scale;
    final double h = imageSize.height * scale;
    final double left = (viewport.width - w) / 2;
    final double top = (viewport.height - h) / 2;
    return InkCoordinateMapper._(Rect.fromLTWH(left, top, w, h));
  }

  static double _containScale(Size image, Size viewport) {
    final double sx = viewport.width / image.width;
    final double sy = viewport.height / image.height;
    return sx < sy ? sx : sy;
  }

  /// 화면(뷰포트) 좌표 → 이미지 기준 정규화 좌표(0..1).
  ///
  /// 이미지 영역 밖의 점은 0..1 범위를 벗어난 값으로 그대로 반환한다
  /// (클램프 여부는 호출부 정책 — 주석 도구는 보통 밖 입력을 무시).
  Offset normalize(Offset viewportPoint) {
    return Offset(
      (viewportPoint.dx - fitted.left) / fitted.width,
      (viewportPoint.dy - fitted.top) / fitted.height,
    );
  }

  /// 이미지 기준 정규화 좌표(0..1) → 화면(뷰포트) 좌표.
  Offset denormalize(Offset normalizedPoint) {
    return Offset(
      fitted.left + normalizedPoint.dx * fitted.width,
      fitted.top + normalizedPoint.dy * fitted.height,
    );
  }

  /// 정규화 좌표가 이미지 안(0..1, 경계 포함)인지.
  bool containsNormalized(Offset normalizedPoint) {
    return normalizedPoint.dx >= 0 &&
        normalizedPoint.dx <= 1 &&
        normalizedPoint.dy >= 0 &&
        normalizedPoint.dy <= 1;
  }

  /// 화면 기준 길이(예: 펜 굵기)를 정규화 스케일로 변환.
  /// 가로 기준 하나만 쓴다 — 비율이 유지되므로 세로와 동일 배율.
  double normalizeLength(double viewportLength) => viewportLength / fitted.width;

  /// 정규화 길이 → 화면 길이.
  double denormalizeLength(double normalizedLength) =>
      normalizedLength * fitted.width;
}
