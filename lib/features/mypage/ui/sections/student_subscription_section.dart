import 'package:flutter/material.dart';

import '../../../../app/app_tabs.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../../../design/widgets/empty_state.dart';
import '../../../../design/widgets/primary_button.dart';
import '../../../../design/widgets/quota_bar.dart';
import '../../../../design/widgets/secondary_button.dart';
import '../../../../design/widgets/status_pill.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/mypage_models.dart';
import '../widgets/mypage_section.dart';
import '../../../../core/web_bridge/web_bridge_actions.dart';

/// 학생 구독 현황 섹션 — 멘토별 카드(요금제·갱신일·상태). "질문하러 가기"·"결제 관리(웹)".
/// ★ 잔여 질문수 미확정이면 숫자 대신 구독 상태로만 표기(S4와 동일, 날조 금지).
class StudentSubscriptionSection extends StatelessWidget {
  const StudentSubscriptionSection({
    super.key,
    required this.subscriptions,
    required this.onGoToQuestions,
  });

  final List<SubscriptionCardInfo> subscriptions;

  /// 질문방 탭으로 이동(질문하러 가기).
  final VoidCallback onGoToQuestions;

  @override
  Widget build(BuildContext context) {
    return MyPageSection(
      title: '구독 현황',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (subscriptions.isEmpty)
            EmptyState(
              icon: Icons.bookmark_rounded,
              title: '구독 중인 멘토가 없어요',
              message: '관심 있는 멘토를 구독해 보세요',
              // 기존 탭 전환 경로만 재사용(멘토 찾기 탭). 결제 유도 아님.
              actionLabel: '멘토 찾기',
              onAction: () => TabNavigator.go(AppTab.mentors),
            )
          else
            for (int i = 0; i < subscriptions.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 16, color: ColorTokens.border),
              _SubCard(info: subscriptions[i]),
            ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: '질문하러 가기',
            icon: Icons.forum_rounded,
            onPressed: onGoToQuestions,
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: '구독 관리 (웹)',
            icon: Icons.open_in_new_rounded,
            neutral: true,
            onPressed: () => openBillingManageWeb(context),
          ),
        ],
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  const _SubCard({required this.info});
  final SubscriptionCardInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(info.mentorName, style: AppType.title)),
            const SizedBox(width: 8),
            // D1-B: 상태 도트 + 기존 상태칩(스캔성↑).
            StatusPill(
              label: info.statusLabel,
              tone: info.statusTone,
              showDot: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (info.planLabel != null) AppBadge(label: info.planLabel!, tinted: true),
            if (info.nextRenewal != null)
              Text('다음 갱신 ${Formatters.shortDate(info.nextRenewal!)}',
                  style: AppType.caption),
            // 잔여 바(D1-A)로 못 보여주는 폴백 문구만 텍스트로 유지(한도 정보 없을 때).
            if (info.usage == null || !info.usage!.hasQuota)
              Text(
                info.remaining != null
                    ? '남은 질문 ${info.remaining}개'
                    : (info.isActive ? '구독 상태로 질문 가능' : '구독이 필요해요'),
                style: AppType.caption,
              ),
          ],
        ),
        // D1-A: 주간 잔여 질문권 프로그레스 바(있는 값만 — RPC used/limit).
        if (info.usage != null && info.usage!.hasQuota) ...<Widget>[
          const SizedBox(height: 8),
          QuotaBar(used: info.usage!.used, limit: info.usage!.limit),
        ],
      ],
    );
  }
}
