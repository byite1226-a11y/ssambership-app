import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/ink/ink_coordinate_mapper.dart';
import 'package:ssambership_app/features/scan_annotation/annotation_sketch.dart';

/// 스캔 주석 좌표 정합 — '화면좌표 → 정규화 저장 → 다른 뷰포트 복원 시 이미지상
/// 같은 지점'을 화면 변환 계층(AnnotationSketch + 매퍼)에서 통합 검증한다.
/// (InkCoordinateMapper 자체의 단위 케이스는 재사용하지 않는다.)
void main() {
  const Size imageSize = Size(400, 300);
  final InkCoordinateMapper mapperA = InkCoordinateMapper.contain(
    imageSize: imageSize,
    viewport: const Size(800, 600),
  );
  final InkCoordinateMapper mapperB = InkCoordinateMapper.contain(
    imageSize: imageSize,
    viewport: const Size(320, 900), // 완전히 다른 뷰포트(세로 길쭉).
  );

  // 화면(캔버스-로컬) 변환 클로저 — 화면 코드와 동일한 offset 보정.
  Offset saveA(Offset local) => mapperA.normalize(local + mapperA.fitted.topLeft);
  Offset restoreB(Offset norm) =>
      mapperB.denormalize(norm) - mapperB.fitted.topLeft;
  Offset saveB(Offset local) => mapperB.normalize(local + mapperB.fitted.topLeft);

  test('한 점: 뷰포트 A 정규화 저장 → 뷰포트 B 복원·재정규화가 같은 지점', () {
    // 이미지 정규화 (0.25, 0.75)에 해당하는 A 캔버스-로컬 점.
    const Offset norm = Offset(0.25, 0.75);
    final Offset localA = mapperA.denormalize(norm) - mapperA.fitted.topLeft;

    final Offset savedA = saveA(localA); // 저장값
    expect(savedA.dx, closeTo(0.25, 1e-9));
    expect(savedA.dy, closeTo(0.75, 1e-9));

    // B 뷰포트로 복원 → 다시 정규화 → 동일 정규화 좌표.
    final Offset localB = restoreB(savedA);
    final Offset savedB = saveB(localB);
    expect(savedB.dx, closeTo(0.25, 1e-9));
    expect(savedB.dy, closeTo(0.75, 1e-9));
  });

  test('스케치 단위 왕복: A 정규화 → B 복원 → B 재정규화가 원본과 일치', () {
    // A 캔버스-로컬 좌표의 스케치(점 2개, 선폭 12px).
    final Offset p1 = mapperA.denormalize(const Offset(0.2, 0.3)) -
        mapperA.fitted.topLeft;
    final Offset p2 = mapperA.denormalize(const Offset(0.8, 0.6)) -
        mapperA.fitted.topLeft;
    final Map<String, dynamic> localSketchA = <String, dynamic>{
      'lines': <dynamic>[
        <String, dynamic>{
          'points': <dynamic>[
            <String, dynamic>{'x': p1.dx, 'y': p1.dy, 'pressure': 0.5},
            <String, dynamic>{'x': p2.dx, 'y': p2.dy, 'pressure': 0.5},
          ],
          'color': 0xFF112233,
          'width': 12.0,
        },
      ],
    };

    // 저장: A 로 정규화.
    final Map<String, dynamic> norm = AnnotationSketch.transform(
      localSketchA,
      point: saveA,
      width: (double w) => mapperA.normalizeLength(w),
    );
    // 복원: B 뷰포트 캔버스-로컬로.
    final Map<String, dynamic> localSketchB = AnnotationSketch.transform(
      norm,
      point: restoreB,
      width: (double n) => mapperB.denormalizeLength(n),
    );
    // 재정규화: B 로 다시 정규화 → 원본 정규화와 같아야 한다.
    final Map<String, dynamic> reNorm = AnnotationSketch.transform(
      localSketchB,
      point: saveB,
      width: (double w) => mapperB.normalizeLength(w),
    );

    final List<AnnotationLine> a = AnnotationSketch.parseLines(norm);
    final List<AnnotationLine> b = AnnotationSketch.parseLines(reNorm);
    expect(b.length, a.length);
    for (int i = 0; i < a.length; i++) {
      expect(b[i].width, closeTo(a[i].width, 1e-9));
      for (int j = 0; j < a[i].points.length; j++) {
        expect(b[i].points[j].dx, closeTo(a[i].points[j].dx, 1e-9));
        expect(b[i].points[j].dy, closeTo(a[i].points[j].dy, 1e-9));
      }
    }
    // 정규화 값이 이미지 지점 그대로인지도 확인.
    expect(a.first.points.first.dx, closeTo(0.2, 1e-9));
    expect(a.first.points.first.dy, closeTo(0.3, 1e-9));
  });
}
