import 'package:flutter/material.dart';

import '../widgets/mypage_section.dart';

/// 지원 진입 섹션 — 알림·고객지원·리뷰. 목적지(전용 화면/웹)는 추후 연결 → 현재는 안내.
/// ★ 없는 기능을 있는 척하지 않는다(준비 중 안내). 결제와 무관.
class SupportSection extends StatelessWidget {
  const SupportSection({super.key, this.onOpenNotifications});

  /// 알림 탭으로 보내는 핸드오프(없으면 안내 스낵바).
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
            onTap: () => onOpenNotifications == null
                ? _soon(context, '알림은 알림 탭에서 확인할 수 있어요.')
                : onOpenNotifications!(),
          ),
          MyPageRow(
            icon: Icons.support_agent_rounded,
            label: '고객지원',
            onTap: () => _soon(context, '고객지원은 곧 제공돼요. (준비 중)'),
          ),
          MyPageRow(
            icon: Icons.rate_review_rounded,
            label: '리뷰 작성',
            onTap: () => _soon(context, '리뷰 작성은 곧 제공돼요. (준비 중)'),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
