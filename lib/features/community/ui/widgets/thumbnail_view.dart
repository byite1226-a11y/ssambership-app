import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';

/// 숏폼 썸네일 표시. 네트워크 이미지 실패/부재 시 중립 배경으로 폴백(깨진 이미지 금지).
///
/// ★ 재생 아이콘 오버레이 없음 — 영상 재생 미지원 상태에서 재생될 것처럼
///   보이는 어포던스는 Broken Functionality(P0-4). video_player 도입 시
///   오버레이·탭 재생을 함께 복원한다(docs/PLAY_STORE_REVIEW_PLAN.md 백로그).
class ThumbnailView extends StatelessWidget {
  const ThumbnailView({super.key, this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (url != null && url!.isNotEmpty)
          Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _Placeholder(),
            // 로딩 중/테스트(네트워크 없음)에도 깨지지 않도록 폴백 유지.
            loadingBuilder: (BuildContext c, Widget child,
                ImageChunkEvent? p) => p == null ? child : const _Placeholder(),
          )
        else
          const _Placeholder(),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.elevated,
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, size: 36, color: ColorTokens.muted),
    );
  }
}
