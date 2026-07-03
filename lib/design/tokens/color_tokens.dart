import 'package:flutter/material.dart';

/// 시맨틱 색 토큰.
///
/// ⚠️ 실제 hex 는 '임시 placeholder'다. 웹 다크 + 스카이 단일 강조 확정 후 교체한다.
/// 화면 코드는 raw hex 대신 반드시 이 토큰을 참조한다(나중에 한곳에서 교체 가능).
/// 스카이 단일 강조 + 페이지/표면/엘리베이트 + primary/secondary/muted + accent + 상태색.
class ColorTokens {
  ColorTokens._();

  // ── 표면(배경 계층) — 라이트 테마 ──
  // C안: 앱 배경을 순백(#FFFFFF)으로. 카드(surface)도 흰색이므로, 순백 위에서 카드가
  //   묻히지 않도록 [AppShape.cardSurface] 에서 그림자 강화 + 옅은 경계(border) 병용.
  static const Color page = Color(0xFFFFFFFF); // 앱 배경(순백)
  static const Color surface = Color(0xFFFFFFFF); // 카드 표면(흰색)
  // 입력필드·검색바 등: 순백 배경과 구분되도록 살짝 회색 유지(순백-순백이면 안 보임).
  static const Color elevated = Color(0xFFF1F5F9); // 떠 있는 표면(입력/검색)

  // ── 텍스트/전경 ──
  static const Color primary = Color(0xFF0F172A); // 주요 텍스트(대비 17.85)
  static const Color secondary = Color(0xFF475569); // 보조 텍스트(대비 7.58)
  static const Color muted = Color(0xFF64748B); // 약한 텍스트/구분선(대비 4.76)

  // ── 강조(단일 파랑) — 2단계에서 role-aware 예정 ──
  static const Color accent = Color(0xFF2563EB); // 포인트(웹 파랑, 대비 5.17)
  static const Color accentMuted = Color(0xFF1D4ED8); // 진한 파랑

  // ── 상태색 ──
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEA580C);
  static const Color danger = Color(0xFFDC2626); // 대비 4.83

  // ── 경계/구분선 ──
  static const Color border = Color(0xFFE2E8F0); // 옅은 회색(카드 층 구분)
}
