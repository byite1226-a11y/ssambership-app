import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../design/tokens/typography.dart';
import '../../design/widgets/initial_avatar.dart';
import '../../design/widgets/secondary_button.dart';

/// 마이페이지. 로그인 사용자 기본 정보(이름·역할) + 로그아웃.
/// 구독/충전이 필요하면 web_bridge 로 웹을 연다(앱 내 결제 없음).
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService.instance;
    final String name = auth.displayName;
    final String role = auth.roleLabel;
    // 게스트(둘러보기)로 들어와도 깨지지 않게: 실제 세션 있을 때만 로그아웃 노출.
    final bool signedIn = auth.isSignedIn;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 프로필 헤더 — 이름/역할은 프로필에서 read(없으면 빈 값, 하드코딩 없음).
            Row(
              children: <Widget>[
                InitialAvatar(name: name, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name.isNotEmpty ? name : '내 정보',
                        style: AppTypography.title,
                      ),
                      if (role.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(role, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // 설정 영역(하단): 로그아웃은 기존 AuthService.signOut() 재사용.
            if (signedIn)
              SecondaryButton(
                label: '로그아웃',
                icon: Icons.logout,
                onPressed: () => auth.signOut(),
              ),
          ],
        ),
      ),
    );
  }
}
