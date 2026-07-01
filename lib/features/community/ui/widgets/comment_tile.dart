import 'package:flutter/material.dart';

import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/initial_avatar.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/community_models.dart';

/// 댓글 한 줄. 이니셜아바타 + 작성자명 + 시간 + 본문. 내부 id 비노출.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final CommunityComment comment;

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
                    Text(comment.authorName, style: AppTypography.caption),
                    const SizedBox(width: 8),
                    Text(Formatters.relativeKorean(comment.createdAt),
                        style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
