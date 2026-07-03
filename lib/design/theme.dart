import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import 'role_accent.dart';
import 'tokens/color_tokens.dart';
import 'typography_tokens.dart';

/// 토큰 → ThemeData 빌드. 화면은 raw 색 대신 Theme/토큰을 참조한다.
///
/// 라이트 테마 + 역할색: role 에 따라 강조(accent) 계열만 분기(학생 파랑/멘토 초록).
/// 배경·표면·텍스트·상태색은 [ColorTokens] 공통.
class AppTheme {
  AppTheme._();

  static ThemeData build(AppRole role) {
    final RoleAccent ra = RoleAccent.forRole(role);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: ra.accent,
      brightness: Brightness.light,
    ).copyWith(
      surface: ColorTokens.surface,
      primary: ra.accent,
      onPrimary: ra.onAccent,
      error: ColorTokens.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // 전역 폰트: Pretendard(정적 4종 400/500/600/700 등록). 시스템 폰트 대체.
      fontFamily: 'Pretendard',
      scaffoldBackgroundColor: ColorTokens.page,
      // 하단 탭: 활성 표시(indicator)=역할 soft, 선택 아이콘/라벨=역할 accent.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorTokens.surface,
        indicatorColor: ra.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? ra.accent
                : ColorTokens.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? ra.accent
                : ColorTokens.muted,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorTokens.page,
        foregroundColor: ColorTokens.primary,
        elevation: 0,
        centerTitle: false,
        // 화면 타이틀 = 새 타입 스케일 display(24/w700). 전역 일관.
        titleTextStyle: AppType.display,
      ),
      // 역할 강조색을 화면/위젯이 AppAccent.of(context) 로 읽는다.
      extensions: <ThemeExtension<dynamic>>[ra],
    );
  }
}
