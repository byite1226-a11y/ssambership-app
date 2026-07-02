import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../tokens/color_tokens.dart';

/// 주요 액션 버튼.
/// ★ 강조색은 역할색(학생 파랑/멘토 초록)을 따른다 — AppAccent.of(context).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final RoleAccent ra = AppAccent.of(context);
    final Widget button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ra.accent,
        foregroundColor: ra.onAccent,
        disabledBackgroundColor: ColorTokens.muted,
        disabledForegroundColor: ColorTokens.secondary,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
