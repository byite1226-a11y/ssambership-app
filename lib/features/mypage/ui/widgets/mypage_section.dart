import 'package:flutter/material.dart';

import '../../../../design/spacing_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/app_card.dart';

/// 마이페이지 섹션 컨테이너(제목 + 카드 본문). 세로로 잘게 쪼개지 않게 카드형으로 묶는다.
/// 모든 섹션이 같은 헤더/여백을 쓰도록 공통화(중복 제거).
class MyPageSection extends StatelessWidget {
  const MyPageSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// 제목 우측 보조(예: '조회만' 배지).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.titleBody),
            child: Row(
              children: <Widget>[
                Text(title, style: AppType.title),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
          AppCard(child: child),
        ],
      ),
    );
  }
}

/// 섹션 안의 '한 줄 진입' 행(아이콘 + 라벨 + 우측 chevron/보조). 탭 가능.
class MyPageRow extends StatelessWidget {
  const MyPageRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailingText,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? trailingText;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: ColorTokens.secondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppType.body)),
            if (trailingText != null)
              Text(trailingText!, style: AppType.caption),
            if (showChevron && onTap != null) ...<Widget>[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: ColorTokens.muted),
            ],
          ],
        ),
      ),
    );
  }
}
