import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/secondary_button.dart';
import '../../../../shared/constants/app_constants.dart';
import '../widgets/mypage_section.dart';

/// 설정 섹션 — 알림 토글·약관/개인정보·앱 버전·로그아웃.
/// 로그아웃은 기존 AuthService.signOut() 을 [onLogout] 으로 주입받아 호출(테스트 가능).
class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key, required this.onLogout, this.showLogout = true});

  /// 로그아웃 동작(기본: AuthService.signOut). 화면에서 주입.
  final VoidCallback onLogout;

  /// 실제 세션이 있을 때만 로그아웃 노출(게스트 방어).
  final bool showLogout;

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  // 알림 토글(기기 로컬 UI 상태). TODO: 알림 설정 백엔드 연동 시 영속화.
  bool _notify = true;

  @override
  Widget build(BuildContext context) {
    return MyPageSection(
      title: '설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                Expanded(child: Text('알림 받기', style: AppTypography.body)),
                Switch(
                  value: _notify,
                  onChanged: (bool v) => setState(() => _notify = v),
                  activeThumbColor: ColorTokens.accent,
                ),
              ],
            ),
          ),
          const Divider(height: 12, color: ColorTokens.border),
          MyPageRow(
            icon: Icons.description_outlined,
            label: '이용약관',
            onTap: () => _soon(context),
          ),
          MyPageRow(
            icon: Icons.privacy_tip_outlined,
            label: '개인정보 처리방침',
            onTap: () => _soon(context),
          ),
          MyPageRow(
            icon: Icons.info_outline,
            label: '앱 버전',
            trailingText: AppConstants.appVersion,
            showChevron: false,
          ),
          if (widget.showLogout) ...<Widget>[
            const SizedBox(height: 12),
            SecondaryButton(
              label: '로그아웃',
              icon: Icons.logout,
              onPressed: widget.onLogout,
            ),
          ],
        ],
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('약관·개인정보는 웹에서 확인할 수 있어요. (준비 중)')),
    );
  }
}
