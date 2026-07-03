import 'package:flutter/material.dart';

import '../../../../core/commerce/commerce_policy.dart';
import '../../../../design/shape_tokens.dart';
import '../../../../design/spacing_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../shared/format/formatters.dart';
import '../../../../shared/widgets/commerce_notice_card.dart';
import '../../data/mypage_models.dart';
import '../../format/cash_format.dart';
import '../widgets/mypage_section.dart';

/// 캐시 섹션 — 잔액·최근 내역 '조회만' + "충전하기(웹)". ★ 앱에서 결제/충전 실행 없음.
class CashSection extends StatelessWidget {
  const CashSection({super.key, required this.cash});

  final CashSummary cash;

  @override
  Widget build(BuildContext context) {
    return MyPageSection(
      title: '캐시',
      trailing: const _ReadOnlyBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 숫자 위계(토스식): 라벨 caption 을 작게 위에, 금액을 number(26/w700)로 크게.
          Text('보유 캐시', style: AppType.caption),
          const SizedBox(height: AppSpacing.s4),
          Text(
            // 잔액 미확인이면 숫자 날조 없이 '-' 표기.
            cash.hasBalance ? CashFormat.won(cash.balanceCents!) : '-',
            style: AppType.number,
          ),
          const SizedBox(height: 12),
          if (cash.recent.isEmpty)
            Text('최근 내역이 없어요.', style: AppType.caption)
          else ...<Widget>[
            Text('최근 내역', style: AppType.caption),
            const SizedBox(height: 6),
            for (final CashEntry e in cash.recent) _EntryRow(entry: e),
          ],
          const SizedBox(height: 12),
          // 커머스 제로: 구매 유도(충전하기) 제거 → 비상호작용 안내.
          const CommerceNoticeCard(text: kRechargeNoticeText),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final CashEntry entry;

  @override
  Widget build(BuildContext context) {
    final Color amountColor =
        entry.isCredit ? ColorTokens.success : ColorTokens.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Text(entry.kindLabel, style: AppType.body),
          const SizedBox(width: 8),
          Text(Formatters.shortDate(entry.createdAt),
              style: AppType.caption),
          const Spacer(),
          Text(
            CashFormat.signedWon(entry.deltaCents),
            style: AppType.body.copyWith(
                color: amountColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// '조회만' 배지 — 앱에서 결제하지 않음을 명시.
class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ColorTokens.muted.withOpacity(0.16),
        borderRadius: AppShape.pillRadius,
      ),
      child: Text('조회만',
          style: AppType.caption.copyWith(color: ColorTokens.muted)),
    );
  }
}
