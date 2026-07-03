import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../tokens/color_tokens.dart';
import '../tokens/dimens.dart';

/// 작은 라벨(과목·플랜 등). 한글 라벨만 받는다(영문 코드값 노출 금지 — 호출부에서 매핑).
/// Flutter 기본 Badge 와 구분하려 AppBadge 로 명명.
/// ★과목 태그는 중립(tinted:false)이 기본 — 분류이지 강조가 아니다(STEP3).
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tinted = false,
  });

  final String label;

  /// true 면 accent-tint, false 면 중립.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final Color base = tinted ? AppAccent.of(context).accent : ColorTokens.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: base.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tinted ? AppAccent.of(context).accent : ColorTokens.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
