import 'package:flutter/material.dart';

import '../../design/tokens/color_tokens.dart';

/// 부팅 스플래시(세션 복원/프로필 로드 중). 로드 끝나면 진입 가드가 이동시킨다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: ColorTokens.accent),
      ),
    );
  }
}
