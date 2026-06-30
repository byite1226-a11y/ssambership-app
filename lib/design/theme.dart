import 'package:flutter/material.dart';
import 'tokens/color_tokens.dart';

/// 토큰 → ThemeData 빌드. 화면은 raw 색 대신 Theme/토큰을 참조한다.
class AppTheme {
  AppTheme._();

  static ThemeData build() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: ColorTokens.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: ColorTokens.surface,
      primary: ColorTokens.accent,
      error: ColorTokens.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ColorTokens.page,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ColorTokens.surface,
        indicatorColor: ColorTokens.elevated,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorTokens.page,
        foregroundColor: ColorTokens.primary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
