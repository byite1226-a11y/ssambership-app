import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../tokens/color_tokens.dart';

/// 가로 스크롤 칩 행(멘토 전환 칩 등). 활성 칩은 accent-tint, 비활성은 중립.
/// 라벨은 한글만(영문 코드 노출 금지).
class ChipScroll extends StatelessWidget {
  const ChipScroll({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// 가로 스크롤 영역의 안쪽 여백. 화면 가장자리까지 스크롤되며 끝 칩이 잘리지 않도록
  /// 좌우 여백을 스크롤 영역 '안'에 둔다(부모가 좌우 패딩으로 감싸면 끝이 잘려 보임).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: labels[i],
                active: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RoleAccent ra = AppAccent.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? ra.accentSoft : ColorTokens.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? ra.accent : ColorTokens.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? ra.accent : ColorTokens.secondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
