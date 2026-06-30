import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/tokens/typography.dart';

/// 로그인(자리). 회원가입 폼은 앱에서 제외(흔적 없이) — 로그인 골격만.
/// 실제 인증 연동은 후속 세션. 지금은 탭 화면으로 진입하는 버튼만.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('로그인 화면(자리)', style: AppTypography.title),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/home'),
              style: FilledButton.styleFrom(backgroundColor: ColorTokens.accent),
              child: const Text('둘러보기'),
            ),
          ],
        ),
      ),
    );
  }
}
