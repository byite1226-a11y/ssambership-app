import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../typography_tokens.dart';

/// 빈 화면 공통 위젯(자리). 각 기능 화면이 실제 UI 전까지 이 위젯으로 채워진다.
class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.widgets_outlined, size: 40, color: ColorTokens.muted),
            const SizedBox(height: 12),
            Text(title, style: AppType.title, textAlign: TextAlign.center),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(subtitle!, style: AppType.caption, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
