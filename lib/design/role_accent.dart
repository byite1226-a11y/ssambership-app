import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';

/// 역할별 강조(accent) 색 계층 — ★순수 색 값만★(위젯/화면 로직 없음).
///
/// 웹 정합: 학생·공개=파랑(#2563EB), 멘토=초록(#059669).
/// 상태색(success/warning/danger)·텍스트(primary/secondary/muted)·배경(page/surface)·
/// border 는 역할과 무관하게 [ColorTokens] 공통을 그대로 쓴다. 여기서 분기하는 것은
/// '강조(accent)' 계열뿐이다.
///
/// ThemeExtension 으로 Theme 에 실어 [AppAccent.of] 로 접근한다(화면 하드코딩 금지).
@immutable
class RoleAccent extends ThemeExtension<RoleAccent> {
  const RoleAccent({
    required this.accent,
    required this.accentMuted,
    required this.accentSoft,
    required this.onAccent,
  });

  /// 주 강조 — 버튼 배경·활성 탭·아이콘·큰 강조.
  final Color accent;

  /// 진한 변형 — 작은 텍스트/링크 강조(대비 보강용). 멘토 초록은 작은 글자에 이 값을 쓴다.
  final Color accentMuted;

  /// 연한 배경 — 칩/틴트/soft 배경.
  final Color accentSoft;

  /// accent 위 전경 — 채운 버튼의 텍스트/아이콘.
  final Color onAccent;

  /// 학생·공개(기본): 파랑.
  static const RoleAccent student = RoleAccent(
    accent: Color(0xFF2563EB),
    accentMuted: Color(0xFF1D4ED8),
    accentSoft: Color(0xFFEEF4FF),
    onAccent: Color(0xFFFFFFFF),
  );

  /// 멘토: 초록.
  static const RoleAccent mentor = RoleAccent(
    accent: Color(0xFF059669),
    accentMuted: Color(0xFF047857),
    accentSoft: Color(0xFFECFDF5),
    onAccent: Color(0xFFFFFFFF),
  );

  /// role → 강조색. 멘토만 초록, 그 외(학생/공개/게스트/관리자)는 파랑 폴백.
  static RoleAccent forRole(AppRole role) =>
      role == AppRole.mentor ? mentor : student;

  @override
  RoleAccent copyWith({
    Color? accent,
    Color? accentMuted,
    Color? accentSoft,
    Color? onAccent,
  }) {
    return RoleAccent(
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  RoleAccent lerp(ThemeExtension<RoleAccent>? other, double t) {
    if (other is! RoleAccent) return this;
    return RoleAccent(
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// 위젯·화면에서 현재 역할 강조색 접근점.
/// Theme 확장에서 읽고, 없으면 학생(파랑) 폴백 — 공개/게스트 화면 안전.
class AppAccent {
  AppAccent._();

  static RoleAccent of(BuildContext context) =>
      Theme.of(context).extension<RoleAccent>() ?? RoleAccent.student;
}
