/// 연결 테스트(DoD#2)용 최소 모델. 공개 테이블 1건 read 결과를 담는다.
/// 화면에는 내부 컬럼명/UUID 를 노출하지 않는다(존재 여부/개수만 사용).
library;

class HealthProbe {
  const HealthProbe({required this.ok, this.sampleCount = 0, this.detail});

  final bool ok;
  final int sampleCount;

  /// 내부 디버그용(화면 표시 금지).
  final String? detail;
}
