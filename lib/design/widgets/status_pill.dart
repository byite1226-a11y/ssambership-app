import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';

/// 상태 칩의 의미색(시맨틱 토큰에만 매핑 — hex 하드코딩 금지).
enum StatusTone { neutral, info, success, warning, danger }

/// 상태 한글 칩. 예: 답변대기/진행중/답변완료/분쟁.
/// label 은 '한글'만 받는다(영문 enum/코드 노출 금지). 색은 tone → 시맨틱 토큰.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  Color get _color {
    switch (tone) {
      case StatusTone.success:
        return ColorTokens.success;
      case StatusTone.warning:
        return ColorTokens.warning;
      case StatusTone.danger:
        return ColorTokens.danger;
      case StatusTone.info:
        return ColorTokens.accent;
      case StatusTone.neutral:
        return ColorTokens.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.36)),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
