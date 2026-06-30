import 'package:flutter/material.dart';
import 'color_tokens.dart';

/// 타이포 토큰. 폰트 패밀리는 추후 확정(시스템 기본 우선).
/// 크기/굵기만 시맨틱하게 정의하고 색은 ColorTokens 를 따른다.
class AppTypography {
  AppTypography._();

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: ColorTokens.primary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ColorTokens.primary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorTokens.primary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ColorTokens.secondary,
  );
}
