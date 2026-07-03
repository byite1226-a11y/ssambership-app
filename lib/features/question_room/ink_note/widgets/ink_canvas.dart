import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../../../design/tokens/color_tokens.dart';

/// 필기 캔버스 — Scribble 위젯을 감싸 논리 크기를 상위에 알린다.
///
/// ★ 배경 흰색 고정: 필기 가독성을 위한 '콘텐츠 영역'이라 디자인 토큰 교체와 무관하다.
/// ★ 크기 측정: LayoutBuilder 로 실제 캔버스 논리 크기를 재 [onCanvasSize] 로 전달한다.
///   상위는 이 값을 ScribbleInkAdapter.exportDocument 의 canvasSize 로 쓴다(좌표 정합 기준).
class InkCanvas extends StatelessWidget {
  const InkCanvas({
    super.key,
    required this.notifier,
    required this.onCanvasSize,
  });

  final ScribbleNotifier notifier;

  /// 캔버스 논리 크기가 확정/변경될 때마다 호출(빌드 이후 프레임에 전달).
  final ValueChanged<Size> onCanvasSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        // 빌드 도중 setState 유발을 피하려 다음 프레임에 크기를 알린다.
        WidgetsBinding.instance.addPostFrameCallback((_) => onCanvasSize(size));
        return Container(
          decoration: BoxDecoration(
            color: Colors.white, // 필기 가독성 — 콘텐츠 영역이므로 흰색 고정.
            border: Border.all(color: ColorTokens.border), // 라이트 배경과 캔버스 경계 구분
          ),
          child: Scribble(notifier: notifier),
        );
      },
    );
  }
}
