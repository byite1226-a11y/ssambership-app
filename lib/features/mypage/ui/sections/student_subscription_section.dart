import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../../../design/widgets/primary_button.dart';
import '../../../../design/widgets/secondary_button.dart';
import '../../../../design/widgets/status_pill.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/mypage_models.dart';
import '../widgets/mypage_section.dart';
import '../widgets/mypage_web_bridge.dart';

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('아직 구독 중인 멘토가 없어요. 멘토를 구독하면 여기에 표시돼요.',
                  style: AppTypography.caption),
            )
          else
            for (int i = 0; i < subscriptions.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 20, color: ColorTokens.border),
              _SubCard(info: subscriptions[i]),
            ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: '질문하러 가기',
            icon: Icons.forum_outlined,
            onPressed: onGoToQuestions,
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: '결제·구독 관리 (웹)',
            icon: Icons.open_in_new,
            onPressed: () => openManagePaymentsWeb(context),
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
            Expanded(child: Text(info.mentorName, style: AppTypography.body)),
            const SizedBox(width: 8),
            StatusPill(
              label: info.statusLabel,
              tone: info.isActive ? StatusTone.success : StatusTone.warning,
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
                  style: AppTypography.caption),
            // 잔여 질문수: 확정값 있으면 숫자, 없으면 상태로(날조 금지).
            Text(
              info.remaining != null
                  ? '남은 질문 ${info.remaining}개'
                  : (info.isActive ? '구독 상태로 질문 가능' : '구독이 필요해요'),
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    );
  }
}
