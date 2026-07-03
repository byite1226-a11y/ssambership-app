import 'package:flutter/material.dart';

import '../shape_tokens.dart';
import 'status_pill.dart';

/// 카운트 배지(D1-D) — 주목 필요한 개수를 원형/pill 배지로. ★값(count)만 받는 순수 위젯★.
///
/// 색 = tone(기본 info=역할 accent). solid 배경 + 흰 숫자(스캔성↑, tabular).
/// count ≤ 0 이면 아무것도 그리지 않는다. [max] 초과는 'max+'(예: 99+).
class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.count,
    this.tone = StatusTone.info,
    this.max = 99,
  });

  final int count;
  final StatusTone tone;
  final int max;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final Color c = statusToneColor(context, tone);
    final String text = count > max ? '$max+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, borderRadius: AppShape.pillRadius),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
