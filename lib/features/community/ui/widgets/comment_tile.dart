import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/initial_avatar.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/community_models.dart';

/// 댓글 한 줄. 이니셜아바타 + 작성자명 + 시간 + 본문. 내부 id 비노출.
/// [onBlock] 지정 시 우측 ⋯ 메뉴에 '이 사용자 차단' 노출.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, this.onBlock});

  final CommunityComment comment;
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
          if (onBlock != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded,
                  size: 18, color: ColorTokens.muted),
              tooltip: '더보기',
              onSelected: (String v) {
                if (v == 'block') onBlock!();
              },
              itemBuilder: (BuildContext ctx) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                    value: 'block', child: Text('이 사용자 차단')),
              ],
            ),
        ],
      ),
    );
  }
}
