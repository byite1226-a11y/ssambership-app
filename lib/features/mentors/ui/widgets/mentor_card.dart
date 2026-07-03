import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../../../design/widgets/app_card.dart';
import '../../../../design/widgets/initial_avatar.dart';
import '../../data/mentor_models.dart';
import 'mentor_meta_item.dart';

/// 멘토 목록 카드(열람 전용). 탭하면 상세로, '구독하기'는 웹 브릿지로 연결.
class MentorCard extends StatelessWidget {
  const MentorCard({super.key, required this.item, required this.onOpen});

  final MentorListItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final MentorProfileInfo? profile = item.profile;
    final List<String> subjects = item.subjects;
    final String? school = profile?.schoolLine;
    final String? intro = profile?.introLine?.trim();

    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InitialAvatar(name: item.displayName, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            item.displayName,
                            style: AppType.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isVerified) ...<Widget>[
                          const SizedBox(width: 6),
                          const AppBadge(label: '인증', tinted: true),
                        ],
                      ],
                    ),
                    if (school != null) ...<Widget>[
                      const SizedBox(height: 3),
                      // 대학·학과 → school 아이콘(보조색).
                      MentorMetaItem(icon: Icons.school_rounded, text: school),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (subjects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            // 담당 과목/태그 → menu_book 아이콘(보조색) + 기존 칩(로직·색 불변).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.menu_book_rounded,
                      size: 16, color: ColorTokens.secondary),
                ),
                const SizedBox(width: 5),
                Expanded(child: _SubjectChips(subjects: subjects)),
              ],
            ),
          ],
          if (intro != null && intro.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              intro,
              style: AppType.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          // 커머스 제로: 구매 유도(구독하기) 버튼 제거. 가격은 '표시'만 유지,
          // 구독 진입은 카드 탭 → 멘토 상세로 이동(구매 유도 아님).
          // 요금 표시 → payments 아이콘(보조색). 결제 유도 아님.
          MentorMetaItem(
            icon: Icons.payments_rounded,
            text: item.priceSummary,
            style: AppType.body,
          ),
        ],
      ),
    );
  }
}

/// 과목 칩(최대 4개 + 초과분은 '+N'). 라벨은 이미 한글로 내려온 값을 그대로 쓴다.
class _SubjectChips extends StatelessWidget {
  const _SubjectChips({required this.subjects});

  final List<String> subjects;

  @override
  Widget build(BuildContext context) {
    const int maxShown = 4;
    final List<String> shown = subjects.take(maxShown).toList();
    final int extra = subjects.length - shown.length;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final String s in shown) AppBadge(label: s),
        if (extra > 0) AppBadge(label: '+$extra'),
      ],
    );
  }
}
