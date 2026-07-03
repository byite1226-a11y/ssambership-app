import 'package:flutter/material.dart';
import '../shape_tokens.dart';
import '../spacing_tokens.dart';

/// 카드 컨테이너(모바일 패딩·라운드). 화면 카드의 기본 뼈대.
///
/// 표면 전환(elevation): 테두리 대신 흰 배경 + 은은한 그림자 1개로 층을 만든다
/// ([AppShape.cardSurface]). 반경 16 통일. 내부 패딩 기본 16.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      width: double.infinity,
      padding: padding,
      decoration: AppShape.cardSurface,
      child: child,
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShape.cardRadius,
        child: body,
      ),
    );
  }
}
