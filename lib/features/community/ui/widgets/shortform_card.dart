import 'package:flutter/material.dart';

import '../../../../design/shape_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../data/community_models.dart';
import 'thumbnail_view.dart';

/// 숏폼 카드(세로 피드 한 칸). 썸네일+재생 어포던스·제목·멘토배지·좋아요·조회수.
/// ★ 실제 영상 재생 플러그인은 없다 — 썸네일 위 재생 아이콘(어포던스)만. 상세에서도 동일.
class ShortformCard extends StatelessWidget {
  const ShortformCard({super.key, required this.post, required this.onOpen});

  final ShortformPost post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: AppShape.cardSurface,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ThumbnailView(url: post.thumbnailUrl, playable: true),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(post.title,
                      style: AppType.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      if (post.authorRole == 'mentor')
                        const AppBadge(label: '멘토', tinted: true),
                      if (post.authorRole == 'mentor')
                        const SizedBox(width: 6),
                      Text(post.authorName, style: AppType.caption),
                      const Spacer(),
                      const Icon(Icons.favorite_border,
                          size: 15, color: ColorTokens.muted),
                      const SizedBox(width: 3),
                      Text('${post.likeCount}', style: AppType.caption),
                      const SizedBox(width: 12),
                      const Icon(Icons.visibility_outlined,
                          size: 15, color: ColorTokens.muted),
                      const SizedBox(width: 3),
                      Text('${post.viewCount}', style: AppType.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
