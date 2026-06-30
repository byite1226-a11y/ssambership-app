import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design/tokens/typography.dart';
import '../../design/tokens/color_tokens.dart';
import '../../shared/constants/app_constants.dart';

/// 온보딩(자리). 진입 → 로그인으로 넘어가는 골격만.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(AppConstants.appDisplayName, style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            const Text('질문 멘토링, 모바일에서', style: AppTypography.caption),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(backgroundColor: ColorTokens.accent),
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
