import 'package:flutter/material.dart';
import 'color_tokens.dart';

/// 타이포 토큰(위계). 폰트 패밀리는 시스템 기본 유지 — 크기/굵기/색만 시맨틱 정의.
/// 위계: 화면제목(titleLarge) > 섹션(sectionTitle) > 카드제목(cardTitle) > 본문(body) > 캡션/메타.
/// 색은 ColorTokens 공통(제목=primary, 캡션=secondary, 메타=muted). 강조색은 호출부에서 AppAccent.
class AppTypography {
  AppTypography._();

  /// 화면 제목(앱바) — 22 bold.
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: ColorTokens.primary,
  );

  /// 큰 제목(모달 등) — 18 bold.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ColorTokens.primary,
  );

  /// 섹션 제목("구독 현황" 등) — 16 semibold.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ColorTokens.primary,
  );

  /// 카드 제목(리스트 아이템 제목) — 15 semibold.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ColorTokens.primary,
  );

  /// 본문 — 14.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorTokens.primary,
  );

  /// 캡션 — 12(보조 텍스트).
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ColorTokens.secondary,
  );

  /// 메타(날짜·시간 등 흐린 정보) — 12 muted.
  static const TextStyle meta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ColorTokens.muted,
  );
}
