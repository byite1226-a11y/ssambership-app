import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/models/question_message.dart';

/// 카카오톡식 말풍선(공통). 학생 채팅·멘토 답변 화면이 함께 쓴다.
///
/// ★ [mine] = 현재 로그인 사용자의 메시지 → 우측(accent). 상대 → 좌측(surface).
///   학생 화면에선 학생=우측/멘토=좌측, 멘토 화면에선 멘토=우측/학생=좌측로
///   자동으로 '거울상'이 된다(author_id == 내 uid 기준).
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.mine});

  final QuestionMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final Color bg = mine ? ColorTokens.accent : ColorTokens.surface;
    final Color fg = mine ? ColorTokens.page : ColorTokens.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (mine)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(Formatters.hourMinute(message.createdAt),
                  style: AppTypography.caption),
            ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: mine ? null : Border.all(color: ColorTokens.border),
              ),
              child: Text(message.body,
                  style: AppTypography.body.copyWith(color: fg)),
            ),
          ),
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(Formatters.hourMinute(message.createdAt),
                  style: AppTypography.caption),
            ),
        ],
      ),
    );
  }
}
