import 'package:flutter/material.dart';

import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../../../design/widgets/app_card.dart';
import '../../../../design/widgets/status_pill.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/models/individual_question_models.dart';

/// 상태 → 시맨틱 톤(웹 배지색 규약 미러: released(답변완료)=info,
/// answered(답변 도착)=success, 진행(예치·공개·답변중)=warning,
/// 종결(환불·만료·취소)=neutral). 톤 매핑은 미변경 — 라벨 문구만 앱 전용.
StatusTone iqStatusTone(IndividualQuestionStatus s) {
  switch (s) {
    case IndividualQuestionStatus.released:
      return StatusTone.info;
    case IndividualQuestionStatus.answered:
      return StatusTone.success;
    case IndividualQuestionStatus.escrowed:
    case IndividualQuestionStatus.assigned:
    case IndividualQuestionStatus.open:
    case IndividualQuestionStatus.claimed:
      return StatusTone.warning;
    case IndividualQuestionStatus.refunded:
    case IndividualQuestionStatus.expired:
    case IndividualQuestionStatus.canceled:
    case IndividualQuestionStatus.unknown:
      return StatusTone.neutral;
  }
}

/// 상태 칩(한글 라벨만).
class IqStatusPill extends StatelessWidget {
  const IqStatusPill({super.key, required this.status});

  final IndividualQuestionStatus status;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: iqStatusLabel(status),
      tone: iqStatusTone(status),
    );
  }
}

/// 목록용 질문 카드 — 제목·유형·가격·상태·마감 남은시간.
class IqQuestionCard extends StatelessWidget {
  const IqQuestionCard({
    super.key,
    required this.question,
    this.onTap,
  });

  final IndividualQuestion question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String? remaining =
        formatIqExpiryRemaining(question.expiresAt, question.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppBadge(label: iqTypeLabel(question.type), tinted: true),
                  const SizedBox(width: 6),
                  IqStatusPill(status: question.status),
                  const Spacer(),
                  Text(
                    formatIqCash(question.priceCents),
                    style: AppTypography.body,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question.title.isEmpty ? '(제목 없음)' : question.title,
                style: AppTypography.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  if (question.createdAt != null)
                    Text(
                      Formatters.relativeKorean(question.createdAt!),
                      style: AppTypography.caption,
                    ),
                  if (remaining != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(remaining, style: AppTypography.caption),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 멘토용 공개 대기 질문 카드(위생 필드만 — 본문·학생 정보 없음).
class IqOpenQuestionCard extends StatelessWidget {
  const IqOpenQuestionCard({
    super.key,
    required this.question,
    this.onClaim,
  });

  final OpenIndividualQuestion question;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final String? remaining = formatIqExpiryRemaining(
      question.expiresAt,
      IndividualQuestionStatus.open,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const AppBadge(label: '공개형', tinted: true),
                const Spacer(),
                Text(
                  formatIqCash(question.priceCents),
                  style: AppTypography.body,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.title.isEmpty ? '(제목 없음)' : question.title,
              style: AppTypography.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (remaining != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(remaining, style: AppTypography.caption),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClaim,
                child: const Text('수락하고 답변하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
