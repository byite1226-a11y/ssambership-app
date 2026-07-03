import 'package:flutter/material.dart';

import '../../../../app/app_tabs.dart';
import '../../../../core/web_bridge/web_bridge_actions.dart';
import '../widgets/mypage_section.dart';

/// 지원 진입 섹션 — 알림·고객지원·리뷰. 알림=인앱 탭 전환, 고객지원·리뷰=웹.
class SupportSection extends StatelessWidget {
  const SupportSection({super.key, this.onOpenNotifications});

  /// 알림 탭으로 보내는 핸드오프(없으면 TabNavigator 로 알림 탭 전환).
  final VoidCallback? onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return MyPageSection(
      title: '알림 · 지원',
      child: Column(
        children: <Widget>[
          MyPageRow(
            icon: Icons.notifications_rounded,
            label: '알림',
            onTap: () => (onOpenNotifications ??
                () => TabNavigator.go(AppTab.notifications))(),
          ),
          MyPageRow(
            icon: Icons.support_agent_rounded,
            label: '고객지원',
            onTap: () => openSupportWeb(context),
          ),
          MyPageRow(
            icon: Icons.rate_review_rounded,
            label: '리뷰 작성',
            onTap: () => openReviewsWeb(context),
          ),
        ],
      ),
    );
  }
}
