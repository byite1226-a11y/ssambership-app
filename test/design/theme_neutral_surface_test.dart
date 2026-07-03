import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/auth/auth_service.dart';
import 'package:ssambership_app/design/role_accent.dart';
import 'package:ssambership_app/design/theme.dart';
import 'package:ssambership_app/design/tokens/color_tokens.dart';

/// seed 오염 회귀 방지: ColorScheme 파생 표면 슬롯이 역할 hue 로 물들지 않고
/// 중립 토큰이어야 한다(멘토 초록·학생 파랑 무관). 역할색은 primary 슬롯에만.
void main() {
  ColorScheme schemeFor(AppRole role) => AppTheme.build(role).colorScheme;

  for (final AppRole role in <AppRole>[AppRole.student, AppRole.mentor]) {
    group('role=$role', () {
      final ColorScheme s = schemeFor(role);

      test('파생 표면 슬롯 = 중립 토큰(역할 hue 아님)', () {
        expect(s.surface, ColorTokens.surface);
        expect(s.surfaceContainerLowest, ColorTokens.surface);
        expect(s.surfaceContainerLow, ColorTokens.surface);
        expect(s.surfaceContainer, ColorTokens.elevated);
        expect(s.surfaceContainerHigh, ColorTokens.elevated);
        expect(s.surfaceContainerHighest, ColorTokens.elevated); // Switch·filled TextField
        expect(s.secondaryContainer, ColorTokens.elevated); // Chip(filled)·tonal
        expect(s.outline, ColorTokens.border);
      });

      test('surfaceTint = transparent(elevation 오버레이 틴트 제거)', () {
        expect(s.surfaceTint, Colors.transparent);
      });

      test('역할 강조색은 primary 슬롯에만 유지', () {
        expect(s.primary, RoleAccent.forRole(role).accent);
      });
    });
  }

  test('멘토·학생 표면은 동일(중립)·primary만 다름', () {
    final ColorScheme st = schemeFor(AppRole.student);
    final ColorScheme me = schemeFor(AppRole.mentor);
    // 파생 표면이 role 과 무관하게 동일 → 배경 오염 없음.
    expect(me.surfaceContainer, st.surfaceContainer);
    expect(me.surfaceContainerHighest, st.surfaceContainerHighest);
    expect(me.secondaryContainer, st.secondaryContainer);
    expect(me.surfaceTint, st.surfaceTint);
    // primary(강조)만 role 로 분기.
    expect(me.primary, isNot(equals(st.primary)));
    expect(st.primary, const Color(0xFF2563EB)); // 학생 파랑
    expect(me.primary, const Color(0xFF059669)); // 멘토 초록
  });
}
