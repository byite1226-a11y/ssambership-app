import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/typography_tokens.dart';
import '../../design/widgets/primary_button.dart';
import '../../design/widgets/secondary_button.dart';

/// 차단 화면: 계정 정지/제한, 상태 불명, 관리자 계정 등으로 앱 이용 불가일 때.
/// 사유 안내 + 로그아웃(+ 상태 불명이면 재시도).
class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService.instance;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 44, color: ColorTokens.muted),
                const SizedBox(height: 14),
                const Text(
                  '앱을 이용할 수 없어요',
                  style: AppType.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  auth.blockedMessage,
                  style: AppType.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (auth.isRecoverableBlock) ...<Widget>[
                  SecondaryButton(
                    label: '다시 시도',
                    onPressed: () => auth.reloadProfile(),
                  ),
                  const SizedBox(height: 10),
                ],
                PrimaryButton(
                  label: '로그아웃',
                  onPressed: () => auth.signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
