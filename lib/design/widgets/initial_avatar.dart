import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../tokens/color_tokens.dart';

/// 이니셜 아바타. 사진이 없으면 이름 첫 글자 + 중립/accent-tint 배경을 쓴다.
/// ★ 사진 없을 때 깨진 이미지/카메라 placeholder 를 절대 쓰지 않는다.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.tinted = true,
  });

  final String name;
  final double size;

  /// true: accent-tint 배경 / false: 중립 배경.
  final bool tinted;

  String get _initial {
    final String t = name.trim();
    if (t.isEmpty) return '?';
    // 유니코드 안전: 첫 코드포인트 1자.
    return String.fromCharCode(t.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = AppAccent.of(context).accent;
    final Color base = tinted ? accent : ColorTokens.muted;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: base.withOpacity(0.20),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initial,
        style: TextStyle(
          color: tinted ? accent : ColorTokens.primary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
