import 'package:flutter/material.dart';

import '../../../../design/role_accent.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../core/web_bridge/web_bridge_actions.dart';
import '../../../../design/widgets/secondary_button.dart';
import '../../../../features/community/ui/blocks/blocked_users_screen.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../data/notification_settings_repository.dart';
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
  final NotificationSettingsRepository _settings =
      const NotificationSettingsRepository();

  // 알림 토글. 저장된 값이 있으면 로드해 초기화(없으면 기본 켜짐). 저장은 graceful.
  bool _notify = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadNotify();
  }

  Future<void> _loadNotify() async {
    final bool? saved = await _settings.loadEnabled();
    if (saved != null && mounted) setState(() => _notify = saved);
  }

  /// 회원 탈퇴 — 웹 열기 전에 되돌릴 수 없음 고지 + 재확인(P0-1 앱측 잔여).
  /// '계속'을 눌러야만 기존 웹 브릿지 액션을 그대로 호출한다.
  Future<void> _confirmAccountDelete() async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
            '탈퇴하면 계정과 데이터가 삭제되며 되돌릴 수 없어요.\n'
            '탈퇴 절차는 웹 페이지에서 진행돼요. 계속할까요?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '계속',
              style: TextStyle(color: ColorTokens.danger),
            ),
          ),
        ],
      ),
    );
    if (proceed == true && mounted) {
      await openAccountDeleteWeb(context);
    }
  }

  /// 토글 변경 → 로컬 즉시 반영 + 영속화 시도. 실패해도 로컬은 유지(앱 안 죽음).
  Future<void> _onNotifyChanged(bool v) async {
    setState(() {
      _notify = v;
      _saving = true;
    });
    final bool ok = await _settings.saveEnabled(v);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 설정 저장은 준비 중이에요. (이 기기에서만 적용돼요)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyPageSection(
      icon: Icons.settings_rounded,
      title: '설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                Expanded(child: Text('알림 받기', style: AppType.body)),
                Switch(
                  value: _notify,
                  onChanged: _saving ? null : _onNotifyChanged,
                  activeThumbColor: AppAccent.of(context).accent,
                ),
              ],
            ),
          ),
          const Divider(height: 12, color: ColorTokens.border),
          MyPageRow(
            icon: Icons.description_rounded,
            label: '이용약관',
            onTap: () => openTermsWeb(context),
          ),
          MyPageRow(
            icon: Icons.privacy_tip_rounded,
            label: '개인정보 처리방침',
            onTap: () => openPrivacyWeb(context),
          ),
          MyPageRow(
            icon: Icons.info_rounded,
            label: '앱 버전',
            trailingText: AppConstants.appVersion,
            showChevron: false,
          ),
          // 계정: 차단 관리(앱 내) + 회원 탈퇴(웹 링크). 로그인 세션일 때만 노출.
          if (widget.showLogout) ...<Widget>[
            const Divider(height: 12, color: ColorTokens.border),
            MyPageRow(
              icon: Icons.block_rounded,
              label: '차단 관리',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BlockedUsersScreen(),
                ),
              ),
            ),
            MyPageRow(
              icon: Icons.person_remove_rounded,
              label: '회원 탈퇴',
              onTap: _confirmAccountDelete,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: '로그아웃',
              icon: Icons.logout_rounded,
              onPressed: widget.onLogout,
            ),
          ],
        ],
      ),
    );
  }
}
