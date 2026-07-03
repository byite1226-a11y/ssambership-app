/// 간격 스케일(단일 소스). "AI 기본값" 제거 토대 4가지 중 '간격'.
///
/// 스텝: 4 / 8 / 12 / 16 / 20 / 24 / 32. 화면은 임의 간격 대신 이 상수만 참조한다.
/// 규칙(시맨틱 별칭): 화면 좌우 20(토스 기준) · 섹션 사이 24 · 카드 사이 12 · 카드 내부 패딩 16 · 제목-본문 8.
library;

class AppSpacing {
  AppSpacing._();

  // ── 원자 스텝 ──
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // ── 시맨틱 별칭(규칙 고정) ──
  /// 섹션과 섹션 사이.
  static const double section = s24;

  /// 카드와 카드 사이(리스트 아이템 간격).
  static const double cardGap = s12;

  /// 카드 내부 패딩.
  static const double cardPad = s16;

  /// 제목과 본문 사이.
  static const double titleBody = s8;

  /// 화면 좌우 기본 패딩(토스 기준 16보다 넓게 20).
  static const double screenH = s20;
}
