import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../tokens/color_tokens.dart';

/// 남은 질문 표기. ★ 반드시 "잔여 N개" 형식 — '0/4' 같은 분수 표기 금지.
class QuotaText extends StatelessWidget {
  const QuotaText({
    super.key,
    required this.remaining,
    this.emphasize = true,
  });

  /// 남은 개수(미확정/없음이면 호출부에서 이 위젯을 쓰지 않는다).
  final int remaining;

  /// true 면 accent 강조.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Text(
      '잔여 $remaining개',
      style: TextStyle(
        // 작은 텍스트 강조 — 대비 보강 위해 accentMuted(멘토 초록도 진한 값).
        color: emphasize ? AppAccent.of(context).accentMuted : ColorTokens.primary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
