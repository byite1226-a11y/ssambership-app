import 'package:flutter/material.dart';

import 'tokens/color_tokens.dart';

/// 반경·표면(elevation) 토큰(단일 소스). "AI 기본값" 제거 토대 4가지 중 '반경'·'표면'.
///
/// 반경 통일: 카드 16 · 버튼/입력 12 · 칩/뱃지 완전 pill(999).
/// 표면 전환: 카드는 '테두리 나누기' 대신 흰 배경 + 은은한 그림자 1개로 층을 만든다.
/// (테두리는 outline 버튼·입력필드에만 남긴다.)
class AppShape {
  AppShape._();

  // ── 반경 ──
  static const double card = 16;
  static const double button = 12;
  static const double input = 12;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(button));
  static const BorderRadius inputRadius =
      BorderRadius.all(Radius.circular(input));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));

  // ── 표면(카드 elevation) ──
  /// 카드 그림자: #0F172A 6% · blur 12 · offset(0,2). 테두리 대신 이 그림자로 층 구분.
  /// 0x0F = 15/255 ≈ 6% 알파(#0F172A on primary).
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  /// 카드 표면 데코레이션(흰 배경 + 반경 16 + 그림자, 테두리 없음).
  static const BoxDecoration cardSurface = BoxDecoration(
    color: ColorTokens.surface,
    borderRadius: cardRadius,
    boxShadow: cardShadow,
  );
}
