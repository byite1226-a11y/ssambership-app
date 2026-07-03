import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../shape_tokens.dart';
import '../tokens/color_tokens.dart';

/// 상태 칩의 의미색(시맨틱 토큰에만 매핑 — hex 하드코딩 금지).
/// info = 역할 강조색(학생 파랑/멘토 초록), 나머지는 공통 시맨틱색.
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

  Color _colorFor(BuildContext context) {
    switch (tone) {
      case StatusTone.success:
        return ColorTokens.success;
      case StatusTone.warning:
        return ColorTokens.warning;
      case StatusTone.danger:
        return ColorTokens.danger;
      case StatusTone.info:
        return AppAccent.of(context).accent;
      case StatusTone.neutral:
        return ColorTokens.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color c = _colorFor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      // 틴트 스타일: 채운 원색 대신 옅은 틴트 배경(12%) + 같은 계열 진한 텍스트.
      // 무거운 외곽선 제거(토스식 soft pill).
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: AppShape.pillRadius,
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
