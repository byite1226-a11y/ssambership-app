import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../../../design/widgets/app_card.dart';
import '../../../../design/widgets/initial_avatar.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/community_labels.dart';
import '../../data/community_models.dart';

/// 게시판 글 카드(리스트 한 행). 카테고리칩·제목·작성자·시간·댓글수·좋아요.
/// ★ 내부 id 는 노출하지 않는다.
class BoardPostCard extends StatelessWidget {
  const BoardPostCard({super.key, required this.post, required this.onOpen});

  final BoardPost post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppBadge(label: communityCategoryLabel(post.category), tinted: true),
              const Spacer(),
              Text(Formatters.relativeKorean(post.createdAt),
                  style: AppType.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.title,
              style: AppType.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              InitialAvatar(name: post.authorName, size: 22, tinted: false),
              const SizedBox(width: 6),
              Text(post.authorName, style: AppType.caption),
              const Spacer(),
              _Metric(icon: Icons.favorite_border, value: post.likeCount),
              const SizedBox(width: 12),
              _Metric(icon: Icons.mode_comment_outlined, value: post.commentCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: ColorTokens.muted),
        const SizedBox(width: 3),
        Text('$value', style: AppType.caption),
      ],
    );
  }
}
