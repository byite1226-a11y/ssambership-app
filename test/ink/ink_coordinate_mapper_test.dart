import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/ink/ink_coordinate_mapper.dart';

/// 좌표 정합 — 기획서가 '가장 흔한 버그 지점'으로 잠근 부분의 회귀 방어선.
void main() {
  test('가로로 긴 이미지: contain fit 이 상하 여백을 만들고 비율을 유지한다', () {
    // 이미지 2000x1000, 뷰포트 400x400 → 표시 400x200, top 100
    final InkCoordinateMapper m = InkCoordinateMapper.contain(
      imageSize: const Size(2000, 1000),
      viewport: const Size(400, 400),
    );
    expect(m.fitted, const Rect.fromLTWH(0, 100, 400, 200));
  });

  test('세로로 긴 이미지: 좌우 여백·중앙 정렬', () {
    final InkCoordinateMapper m = InkCoordinateMapper.contain(
      imageSize: const Size(500, 1000),
      viewport: const Size(400, 400),
    );
    expect(m.fitted, const Rect.fromLTWH(100, 0, 200, 400));
  });

  test('normalize↔denormalize 왕복이 원점을 보존한다', () {
    final InkCoordinateMapper m = InkCoordinateMapper.contain(
      imageSize: const Size(2000, 1000),
      viewport: const Size(400, 400),
    );
    const Offset screen = Offset(200, 200); // 이미지 정중앙
    final Offset norm = m.normalize(screen);
    expect(norm.dx, closeTo(0.5, 1e-9));
    expect(norm.dy, closeTo(0.5, 1e-9));

    final Offset back = m.denormalize(norm);
    expect(back.dx, closeTo(screen.dx, 1e-9));
    expect(back.dy, closeTo(screen.dy, 1e-9));
  });

  test('같은 정규화 좌표는 다른 뷰포트에서도 이미지의 같은 지점을 가리킨다', () {
    // 핵심 정합 시나리오: 태블릿에서 저장 → 폰에서 열기
    const Size image = Size(1600, 900);
    final InkCoordinateMapper tablet = InkCoordinateMapper.contain(
      imageSize: image,
      viewport: const Size(1200, 800),
    );
    final InkCoordinateMapper phone = InkCoordinateMapper.contain(
      imageSize: image,
      viewport: const Size(360, 640),
    );

    const Offset norm = Offset(0.25, 0.75);
    final Offset onTablet = tablet.denormalize(norm);
    final Offset onPhone = phone.denormalize(norm);

    // 각 화면 좌표를 다시 정규화하면 동일한 이미지 좌표로 돌아와야 한다.
    expect(tablet.normalize(onTablet).dx, closeTo(0.25, 1e-9));
    expect(phone.normalize(onPhone).dx, closeTo(0.25, 1e-9));
    expect(tablet.normalize(onTablet).dy, closeTo(0.75, 1e-9));
    expect(phone.normalize(onPhone).dy, closeTo(0.75, 1e-9));
  });

  test('이미지 영역 밖 입력은 0..1 범위를 벗어나고 containsNormalized=false', () {
    final InkCoordinateMapper m = InkCoordinateMapper.contain(
      imageSize: const Size(2000, 1000),
      viewport: const Size(400, 400),
    );
    // 상단 레터박스(여백) 클릭
    final Offset norm = m.normalize(const Offset(200, 50));
    expect(norm.dy, lessThan(0));
    expect(m.containsNormalized(norm), isFalse);
    expect(m.containsNormalized(const Offset(0.5, 0.5)), isTrue);
    expect(m.containsNormalized(const Offset(0, 1)), isTrue); // 경계 포함
  });

  test('길이 정규화 왕복(펜 굵기 보존)', () {
    final InkCoordinateMapper m = InkCoordinateMapper.contain(
      imageSize: const Size(1000, 1000),
      viewport: const Size(500, 500),
    );
    const double stroke = 6.0;
    expect(m.denormalizeLength(m.normalizeLength(stroke)),
        closeTo(stroke, 1e-9));
  });

  test('0 이하 크기는 ArgumentError — 호출부 버그를 조용히 넘기지 않는다', () {
    expect(
      () => InkCoordinateMapper.contain(
        imageSize: Size.zero,
        viewport: const Size(100, 100),
      ),
      throwsArgumentError,
    );
  });
}
