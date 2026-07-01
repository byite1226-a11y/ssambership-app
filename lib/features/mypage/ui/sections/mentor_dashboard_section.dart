import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/secondary_button.dart';
import '../../data/mypage_models.dart';
import '../../format/cash_format.dart';
import '../widgets/mypage_section.dart';
import '../../../../core/web_bridge/web_bridge_actions.dart';

/// 멘토 대시보드 — 답변·정산 요약(조회만). 정산 출금/관리는 웹.
/// ★ IQ(개별질문)·CR(의뢰결제)는 앱 범위 밖 → 표시하지 않는다. 구독·질문방 중심.
class MentorDashboardSection extends StatelessWidget {
  const MentorDashboardSection({
    super.key,
    required this.data,
    required this.onGoToQuestions,
  });

  final MentorDashboard data;

  /// 질문방(받은 학생) 탭으로 이동.
  final VoidCallback onGoToQuestions;

  @override
  Widget build(BuildContext context) {
    return MyPageSection(
      title: '답변 · 정산 요약',
      trailing: const _ReadOnlyBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _Stat(
                  label: '구독 학생',
                  value: '${data.studentCount}명',
                ),
              ),
              Container(width: 1, height: 36, color: ColorTokens.border),
              Expanded(
                child: _Stat(
                  label: '답변 대기',
                  value: '${data.pendingAnswers}건',
                  emphasize: data.pendingAnswers > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text('최근 정산', style: AppTypography.body),
              const Spacer(),
              Text(
                // 정산 데이터 없으면 숫자 날조 없이 '-'.
                data.latestSettlementCents != null
                    ? CashFormat.won(data.latestSettlementCents!)
                    : '-',
                style: AppTypography.title,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: '받은 질문 보기',
            icon: Icons.forum_outlined,
            onPressed: onGoToQuestions,
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: '정산 관리 (웹)',
            icon: Icons.open_in_new,
            onPressed: () => openPayoutManageWeb(context),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: AppTypography.title.copyWith(
            color: emphasize ? ColorTokens.warning : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

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
