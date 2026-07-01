import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';

/// 숏폼 썸네일 표시. 네트워크 이미지 실패/부재 시 중립 배경으로 폴백(깨진 이미지 금지).
/// [playable] 이면 재생 아이콘 오버레이(어포던스 — 실제 재생 플러그인은 없음).
class ThumbnailView extends StatelessWidget {
  const ThumbnailView({super.key, this.url, this.playable = false});

  final String? url;
  final bool playable;

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
        if (playable)
          const Center(
            child: Icon(Icons.play_circle_fill, size: 52, color: Colors.white),
          ),
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
