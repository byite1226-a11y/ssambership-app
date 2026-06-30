import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/typography.dart';
import 'primary_button.dart';

/// 빈 상태: 아이콘 + 문구 + (선택) 액션.
/// ★ '준비 중' 같은 미완성 문구를 쓰지 않는다 — 사용자에게 의미 있는 안내/행동을 준다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: ColorTokens.muted),
            const SizedBox(height: 14),
            Text(title, style: AppTypography.title, textAlign: TextAlign.center),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(message!,
                  style: AppTypography.caption, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 18),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
