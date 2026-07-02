/// 치수 토큰 — 모서리 반경·간격 스케일의 단일 소스(웹 정합).
///
/// 색과 마찬가지로 화면이 raw 값을 흩뿌리지 않고 이 상수를 참조한다.
/// 구조는 바꾸지 않으며, 반경/간격 '값'만 여기서 통일한다.
library;

/// 모서리 반경. 카드 16 / 버튼·입력 12 / 칩 pill(999).
class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double button = 12;
  static const double input = 12;
  static const double pill = 999;
}

/// 간격 스케일(4/8/12/16/24). 좌우 패딩·카드 내부·리스트 간격에 사용.
class AppSpace {
  AppSpace._();

  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x24 = 24;

  /// 화면 좌우 기본 패딩.
  static const double screenH = 16;

  /// 카드 내부 기본 패딩.
  static const double cardPad = 16;

  /// 리스트 아이템 사이 간격.
  static const double listGap = 12;
}
