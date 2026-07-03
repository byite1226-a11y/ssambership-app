import 'package:flutter/material.dart';

import '../../../../design/role_accent.dart';
import '../../../../design/shape_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/models/question_message.dart';

/// 카카오톡식 말풍선(공통). 학생 채팅·멘토 답변 화면이 함께 쓴다.
///
/// ★ [mine] = 현재 로그인 사용자의 메시지 → 우측(accent). 상대 → 좌측(surface).
///   학생 화면에선 학생=우측/멘토=좌측, 멘토 화면에선 멘토=우측/학생=좌측로
///   자동으로 '거울상'이 된다(author_id == 내 uid 기준).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.attachments = const <Widget>[],
  });

  final QuestionMessage message;
  final bool mine;

  /// 이 메시지에 연결된 이미지 첨부 위젯(썸네일). 상위(LiveMessageList)가 만들어 넣는다.
  final List<Widget> attachments;

  @override
  Widget build(BuildContext context) {
    // 색 절제: 내 말풍선만 역할색 '옅은 틴트'(accentSoft), 상대는 페이지보다 한 단계
    // 짙은 중립 회색 표면(elevated). 회색 채움이 구분 역할 → 상대 말풍선 border 제거.
    // 텍스트는 양쪽 다 진한 본문색(옅은 틴트/회색 위 가독).
    final Color bg =
        mine ? AppAccent.of(context).accentSoft : ColorTokens.elevated;
    const Color fg = ColorTokens.primary;
    // 말풍선 폭은 화면의 약 72% 로 제한 — 좁은 화면에서 자연스럽게 줄바꿈, 넓은 화면에서 과도하게 늘어나지 않음.
    final double maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;
    // 카카오톡식 '꼬리' — 보낸 쪽 아래 모서리만 각지게(내=우하단, 상대=좌하단). 반경=카드 토큰.
    const Radius r = Radius.circular(AppShape.card);
    final BorderRadius bubbleRadius = BorderRadius.only(
      topLeft: r,
      topRight: r,
      bottomLeft: mine ? r : const Radius.circular(4),
      bottomRight: mine ? const Radius.circular(4) : r,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (mine)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(Formatters.hourMinute(message.createdAt),
                  style: AppType.caption),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: bubbleRadius,
              ),
              child: Column(
                crossAxisAlignment:
                    mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (message.body.isNotEmpty)
                    Text(message.body,
                        style: AppType.body
                            .copyWith(color: fg, height: 1.35)),
                  for (final Widget a in attachments) ...<Widget>[
                    if (message.body.isNotEmpty || a != attachments.first)
                      const SizedBox(height: 8),
                    a,
                  ],
                ],
              ),
            ),
          ),
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(Formatters.hourMinute(message.createdAt),
                  style: AppType.caption),
            ),
        ],
      ),
    );
  }
}
