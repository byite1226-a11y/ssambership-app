import 'package:flutter/material.dart';

import '../../design/shape_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/typography_tokens.dart';

/// 커머스 제로 안내 카드 — 결제 유도(구독하기·충전하기) 버튼을 대체하는 '비상호작용' 카드.
///
/// ★ 클릭 동작 없음(정보 표시만). 옅은 중립 배경([ColorTokens.elevated]) + 안내 아이콘 +
///   문구. 흰 카드(AppCard)가 아니라 중립 배경을 쓴다(버튼처럼 눌리는 느낌 배제).
///   반경·간격·타이포는 디자인 토큰(AppShape/AppSpacing/AppType) 그대로 사용.
class CommerceNoticeCard extends StatelessWidget {
  const CommerceNoticeCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: const BoxDecoration(
        color: ColorTokens.elevated, // 옅은 중립 배경(bg-neutral 상당)
        borderRadius: AppShape.cardRadius,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_rounded, size: 20, color: ColorTokens.muted),
          const SizedBox(width: AppSpacing.s8),
          Expanded(child: Text(text, style: AppType.body)),
        ],
      ),
    );
  }
}
