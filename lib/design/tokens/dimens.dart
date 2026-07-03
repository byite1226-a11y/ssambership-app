/// 치수 토큰(레거시 호환 shim) — 반경/간격의 단일 소스는 이제
/// `design/shape_tokens.dart`(AppShape) · `design/spacing_tokens.dart`(AppSpacing).
///
/// 기존 화면이 참조하는 [AppRadius]·[AppSpace] API 는 그대로 두되, 값은 새 토큰으로
/// 위임한다(중복 정의 제거, 단일 소스 유지). 신규 코드는 AppShape/AppSpacing 을 쓴다.
library;

import '../shape_tokens.dart';
import '../spacing_tokens.dart';

/// 모서리 반경. 카드 16 / 버튼·입력 12 / 칩 pill(999). → [AppShape] 위임.
class AppRadius {
  AppRadius._();

  static const double card = AppShape.card;
  static const double button = AppShape.button;
  static const double input = AppShape.input;
  static const double pill = AppShape.pill;
}

/// 간격 스케일(4/8/12/16/24/32). → [AppSpacing] 위임.
class AppSpace {
  AppSpace._();

  static const double x4 = AppSpacing.s4;
  static const double x8 = AppSpacing.s8;
  static const double x12 = AppSpacing.s12;
  static const double x16 = AppSpacing.s16;
  static const double x24 = AppSpacing.s24;
  static const double x32 = AppSpacing.s32;

  /// 화면 좌우 기본 패딩.
  static const double screenH = AppSpacing.screenH;

  /// 카드 내부 기본 패딩.
  static const double cardPad = AppSpacing.cardPad;

  /// 리스트 아이템 사이 간격.
  static const double listGap = AppSpacing.cardGap;
}
