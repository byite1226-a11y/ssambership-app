import 'package:flutter/material.dart';

import '../typography_tokens.dart';

/// 금액 강조(D1-C) — 토스식 Number Display. ★표시 전용: 포맷된 문자열만 받음★.
///
/// 라벨(작게, 위) + 금액(크게+굵게, tabular 유지 = [AppType.number]).
/// 화면의 '주인공' 금액(캐시 잔액·정산 등)에만 쓴다. [emphasizeColor] 로 accent 강조 선택.
class MoneyDisplay extends StatelessWidget {
  const MoneyDisplay({
    super.key,
    required this.label,
    required this.amount,
    this.emphasizeColor,
  });

  /// 위에 작게 표기할 라벨(예: '보유 캐시').
  final String label;

  /// 이미 포맷된 금액 문자열(예: '45,000원', '-'). ★앱에서 재계산하지 않는다.★
  final String amount;

  /// 금액 색 강조(선택). null 이면 기본 primary.
  final Color? emphasizeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: AppType.caption),
        const SizedBox(height: 4),
        Text(
          amount,
          style: emphasizeColor == null
              ? AppType.number
              : AppType.number.copyWith(color: emphasizeColor),
        ),
      ],
    );
  }
}
