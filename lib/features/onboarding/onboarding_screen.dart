import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design/tokens/typography.dart';
import '../../design/tokens/color_tokens.dart';
import '../../shared/constants/app_constants.dart';
import '../dev/dev_flags.dart';

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
            // ★ 개발 전용 진입 — 출시 빌드에서는 노출되지 않는다.
            if (kDevToolsEnabled) ...<Widget>[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/dev/gallery'),
                child: const Text('위젯 갤러리 (개발용)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
