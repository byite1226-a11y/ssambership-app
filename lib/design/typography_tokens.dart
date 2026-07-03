import 'package:flutter/material.dart';

import 'tokens/color_tokens.dart';

/// 타입 스케일(단일 소스). "AI 기본값" 제거 토대 4가지 중 '타이포'.
///
/// 폰트 패밀리는 [ThemeData.fontFamily]=Pretendard 로 전역 주입되므로 여기서는
/// family 를 지정하지 않는다(크기·굵기·색·수치 정렬만 시맨틱으로 정의).
/// 위계: display(화면 타이틀) > title(카드제목·섹션) > body(본문) > caption(보조).
/// number 는 잔여·금액 등 수치 전용(고정폭 숫자, tabular figures).
class AppType {
  AppType._();

  /// 화면 타이틀(앱바·페이지 헤더) — 24 / w700.
  static const TextStyle display = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: ColorTokens.primary,
  );

  /// 카드 제목·섹션 제목 — 17 / w600.
  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: ColorTokens.primary,
  );

  /// 본문 — 15 / w400.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: ColorTokens.primary,
  );

  /// 보조 텍스트(캡션·메타) — 13 / w400 / #64748B.
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ColorTokens.muted, // #64748B
  );

  /// 수치(잔여·금액 등) — 26 / w700 / 고정폭 숫자(tabular figures).
  static const TextStyle number = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: ColorTokens.primary,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
}
