import 'package:flutter/material.dart';

/// 시맨틱 색 토큰.
///
/// ⚠️ 실제 hex 는 '임시 placeholder'다. 웹 다크 + 스카이 단일 강조 확정 후 교체한다.
/// 화면 코드는 raw hex 대신 반드시 이 토큰을 참조한다(나중에 한곳에서 교체 가능).
/// 스카이 단일 강조 + 페이지/표면/엘리베이트 + primary/secondary/muted + accent + 상태색.
class ColorTokens {
  ColorTokens._();

  // ── 표면(배경 계층) — TODO: 웹 다크 확정값으로 교체 ──
  static const Color page = Color(0xFF0B1220); // 임시: 최하단 배경(다크)
  static const Color surface = Color(0xFF111A2B); // 임시: 카드 표면
  static const Color elevated = Color(0xFF1A2740); // 임시: 떠 있는 표면

  // ── 텍스트/전경 ──
  static const Color primary = Color(0xFFF1F5F9); // 임시: 주요 텍스트
  static const Color secondary = Color(0xFF94A3B8); // 임시: 보조 텍스트
  static const Color muted = Color(0xFF64748B); // 임시: 약한 텍스트/구분선

  // ── 강조(스카이 단일) — TODO: 스카이 확정 hex ──
  static const Color accent = Color(0xFF38BDF8); // 임시: 스카이 강조
  static const Color accentMuted = Color(0xFF0EA5E9); // 임시: 강조 변형

  // ── 상태색 ──
  static const Color success = Color(0xFF22C55E); // 임시
  static const Color warning = Color(0xFFF59E0B); // 임시
  static const Color danger = Color(0xFFEF4444); // 임시

  // ── 경계/구분선 ──
  static const Color border = Color(0xFF233047); // 임시
}
