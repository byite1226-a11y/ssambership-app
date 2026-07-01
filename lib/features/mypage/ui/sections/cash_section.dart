import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/secondary_button.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/mypage_models.dart';
import '../../format/cash_format.dart';
import '../widgets/mypage_section.dart';
import '../../../../core/web_bridge/web_bridge_actions.dart';

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
          Row(
            children: <Widget>[
              Text('보유 캐시', style: AppTypography.body),
              const Spacer(),
              Text(
                // 잔액 미확인이면 숫자 날조 없이 '-' 표기.
                cash.hasBalance ? CashFormat.won(cash.balanceCents!) : '-',
                style: AppTypography.title,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cash.recent.isEmpty)
            Text('최근 내역이 없어요.', style: AppTypography.caption)
          else ...<Widget>[
            Text('최근 내역', style: AppTypography.caption),
            const SizedBox(height: 6),
            for (final CashEntry e in cash.recent) _EntryRow(entry: e),
          ],
          const SizedBox(height: 12),
          SecondaryButton(
            label: '충전하기 (웹)',
            icon: Icons.open_in_new,
            onPressed: () => openRechargeWeb(context),
          ),
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
          Text(entry.kindLabel, style: AppTypography.body),
          const SizedBox(width: 8),
          Text(Formatters.shortDate(entry.createdAt),
              style: AppTypography.caption),
          const Spacer(),
          Text(
            CashFormat.signedWon(entry.deltaCents),
            style: AppTypography.body.copyWith(
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('조회만',
          style: AppTypography.caption.copyWith(color: ColorTokens.muted)),
    );
  }
}
