import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../tokens/color_tokens.dart';
import '../tokens/dimens.dart';

/// 보조 액션 버튼(외곽선). 강조색은 역할색(학생 파랑/멘토 초록) — AppAccent.of(context).
///
/// [neutral]=true 면 역할색 대신 중립 회색 외곽선을 쓴다(웹 이동 등 '보조 탈출' 버튼 —
/// 강조색 절제: 화면당 역할색은 핵심 액션 1곳 원칙).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.icon,
    this.neutral = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final IconData? icon;
  final bool neutral;

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
    final Color fg = neutral ? ColorTokens.secondary : ra.accent;
    final Color side = neutral ? ColorTokens.border : ra.accent;
    final Widget button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        disabledForegroundColor: ColorTokens.muted,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: side, width: 1.4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
