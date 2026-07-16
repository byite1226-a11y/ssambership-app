import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/initial_avatar.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/community_models.dart';

/// 댓글 한 줄. 이니셜아바타 + 작성자명 + 시간 + 본문. 내부 id 비노출.
/// [onReport] 지정 시 ⋯ 메뉴에 '신고', [onBlock] 지정 시 '이 사용자 차단' 노출.
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.onReport,
    this.onBlock,
  });

  final CommunityComment comment;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InitialAvatar(name: comment.authorName, size: 30, tinted: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(comment.authorName, style: AppType.caption),
                    const SizedBox(width: 8),
                    Text(Formatters.relativeKorean(comment.createdAt),
                        style: AppType.caption),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: AppType.body),
              ],
            ),
          ),
          if (onReport != null || onBlock != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded,
                  size: 18, color: ColorTokens.muted),
              tooltip: '더보기',
              onSelected: (String v) {
                if (v == 'report') onReport?.call();
                if (v == 'block') onBlock?.call();
              },
              itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                if (onReport != null)
                  const PopupMenuItem<String>(
                      value: 'report', child: Text('신고')),
                if (onBlock != null)
                  const PopupMenuItem<String>(
                      value: 'block', child: Text('이 사용자 차단')),
              ],
            ),
        ],
      ),
    );
  }
}
