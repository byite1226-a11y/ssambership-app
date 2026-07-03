import 'package:flutter/material.dart';

import 'tokens/color_tokens.dart';

/// 반경·표면(elevation) 토큰(단일 소스). "AI 기본값" 제거 토대 4가지 중 '반경'·'표면'.
///
/// 반경 통일(콴다풍 부드러운 위계): 카드 20 · 콘텐츠블록 16 · 버튼/입력 12 · 칩/뱃지 pill(999).
/// 표면 전환: 카드는 '테두리 나누기' 대신 흰 배경 + 은은한 그림자로 층을 만든다.
/// (테두리는 outline 버튼·입력필드에만 남긴다.)
class AppShape {
  AppShape._();

  // ── 반경 ──
  /// 카드(콴다처럼 부드럽게 20).
  static const double card = 20;

  /// 카드 내부 콘텐츠 블록(카드보다 한 단계 작게 16).
  static const double block = 16;
  static const double button = 12;
  static const double input = 12;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius blockRadius =
      BorderRadius.all(Radius.circular(block));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(button));
  static const BorderRadius inputRadius =
      BorderRadius.all(Radius.circular(input));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));

  // ── 표면(카드 elevation) ──
  /// 카드 그림자(C안·순백 배경): 콴다 "0 1px 4px" 수준으로 은은하게 강화.
  /// 순백(page=#FFFFFF) 위에서 흰 카드가 묻히지 않도록 STEP A(4~5%)보다 살짝 올린다.
  /// 2겹 — 밀착 그림자(#0F172A ~4% · blur 2 · y1) + 확산 그림자(#0F172A ~6% · blur 6 · y2).
  /// ★여전히 '무거운 그림자'는 금지 — 그림자 + 옅은 경계(아래 cardSurface)로 층을 만든다.★
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A0F172A), // ≈ 4% (10/255) 밀착 엣지
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F0F172A), // ≈ 6% (15/255) 확산 리프트
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// 카드 표면 데코레이션(흰 배경 + 반경 20 + 그림자 + 옅은 경계).
  /// C안: 순백 배경에서 카드 구분을 위해 그림자와 함께 콴다풍 옅은 경계(#E2E8F0)를 병용한다.
  static const BoxDecoration cardSurface = BoxDecoration(
    color: ColorTokens.surface,
    borderRadius: cardRadius,
    boxShadow: cardShadow,
    border: Border.fromBorderSide(
      BorderSide(color: ColorTokens.border, width: 1),
    ),
  );
}
