import 'package:flutter/material.dart';

import '../role_accent.dart';
import '../tokens/color_tokens.dart';
import '../typography_tokens.dart';

/// 주간 질문 잔여 시각화(D1-A) — ★순수 위젯: 값(used·limit)만 받고 새 계산/조회 없음★.
///
/// 채워진 비율 = 잔여/한도. 색 = 역할 accent(학생 파랑/멘토 초록, [AppAccent]).
/// 한도 999+(프리미엄 FUP 등 사실상 무제한)면 바 대신 '무제한' 텍스트.
/// limit ≤ 0(한도 정보 없음)이면 아무것도 그리지 않는다(표시 생략 규칙 유지).
class QuotaBar extends StatelessWidget {
  const QuotaBar({super.key, required this.used, required this.limit});

  final int used;
  final int limit;

  bool get _unlimited => limit >= 999;
  int get _remaining => (limit - used).clamp(0, limit);

  @override
  Widget build(BuildContext context) {
    if (limit <= 0) return const SizedBox.shrink();
    final Color accent = AppAccent.of(context).accent;

    if (_unlimited) {
      return Text(
        '주 무제한 질문',
        style: AppType.caption
            .copyWith(color: accent, fontWeight: FontWeight.w700),
      );
    }

    final double fraction = (_remaining / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('주 $limit개 질문', style: AppType.caption),
            const Spacer(),
            Text(
              '잔여 $_remaining/$limit',
              style: AppType.caption
                  .copyWith(color: accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 트랙(elevated) 위에 잔여 비율만큼 accent 채움. 높이 6, pill 라운드.
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: <Widget>[
                const ColoredBox(
                  color: ColorTokens.elevated,
                  child: SizedBox.expand(),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: ColoredBox(color: accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
