import 'package:flutter/material.dart';

import '../../../../design/shape_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/count_badge.dart';
import '../../../../design/widgets/money_display.dart';
import '../../../../design/widgets/secondary_button.dart';
import '../../../../design/widgets/status_pill.dart';
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
      icon: Icons.insights_rounded,
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
                  count: data.studentCount,
                ),
              ),
              Container(width: 1, height: 36, color: ColorTokens.border),
              Expanded(
                child: _Stat(
                  label: '답변 대기',
                  count: data.pendingAnswers,
                  // 대기 있을 때 warning 배지로 강조. 0이면 배지 대신 차분한 '0'.
                  tone: StatusTone.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 최근 정산 → MoneyDisplay 로 통일(캐시 섹션과 동일 패턴, 값은 그대로).
          MoneyDisplay(
            label: '최근 정산',
            amount: data.latestSettlementCents != null
                ? CashFormat.won(data.latestSettlementCents!)
                : '-',
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: '받은 질문 보기',
            icon: Icons.forum_rounded,
            onPressed: onGoToQuestions,
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: '정산 관리 (웹)',
            icon: Icons.open_in_new_rounded,
            neutral: true,
            onPressed: () => openPayoutManageWeb(context),
          ),
        ],
      ),
    );
  }
}

/// 요약 통계 한 칸 — 카운트를 CountBadge(D-1)로 시각화(0이면 차분한 '0').
class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.count,
    this.tone = StatusTone.info,
  });
  final String label;
  final int count;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 26,
          // Row(center)로 배지를 콘텐츠 크기로 유지(Center의 bounded 제약이 배지를
          // 칸 전체로 늘리는 것 방지). CountBadge 자체는 미변경(다른 사용처 유지).
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (count > 0)
                CountBadge(count: count, tone: tone)
              else
                Text(
                  '0',
                  style: AppType.body.copyWith(
                    color: ColorTokens.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppType.caption),
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
        borderRadius: AppShape.pillRadius,
      ),
      child: Text('조회만',
          style: AppType.caption.copyWith(color: ColorTokens.muted)),
    );
  }
}
