import 'package:flutter/material.dart';

import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/app_badge.dart';
import '../../../design/widgets/app_card.dart';
import '../../../design/widgets/initial_avatar.dart';
import '../../../design/widgets/primary_button.dart';
import '../data/mentor_directory_repository.dart';
import '../data/mentor_models.dart';
import '../format/mentor_price_format.dart';
import '../../../app/app_tabs.dart';
import '../../../core/web_bridge/web_bridge_actions.dart';

/// 멘토 상세(열람 전용). 목록에서 받은 항목을 재사용하고, 평균 답변시간·구독 여부만
/// 추가로 불러온다. CTA 는 구독 상태에 따라 [질문방으로]/[구독하기](웹 브릿지).
class MentorDetailScreen extends StatefulWidget {
  const MentorDetailScreen({super.key, required this.item});

  final MentorListItem item;

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen> {
  final MentorDirectoryRepository _repo = const MentorDirectoryRepository();
  late Future<MentorDetailExtras> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchExtras(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final MentorListItem m = widget.item;
    return Scaffold(
      appBar: AppBar(title: Text(m.displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          _Header(item: m),
          if (m.subjects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _Section(
              title: '지도 과목',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final String s in m.subjects)
                    AppBadge(label: s, tinted: true),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _Section(
            title: '소개',
            child: Text(
              (m.profile?.introLine?.trim().isNotEmpty ?? false)
                  ? m.profile!.introLine!.trim()
                  : '아직 소개가 등록되지 않은 신규 멘토예요.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<MentorDetailExtras>(
            future: _future,
            builder: (BuildContext context,
                AsyncSnapshot<MentorDetailExtras> snap) {
              final MentorDetailExtras extras =
                  snap.data ?? const MentorDetailExtras();
              return _Section(
                title: '활동',
                child: _StatsView(
                  extras: extras,
                  loading: snap.connectionState != ConnectionState.done,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _Section(
            title: '요금제',
            child: _PlansView(plans: m.plans),
          ),
          const SizedBox(height: 8),
          const Text(
            '가격은 표시용이며, 구독은 웹에서 진행돼요.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 24),
          FutureBuilder<MentorDetailExtras>(
            future: _future,
            builder: (BuildContext context,
                AsyncSnapshot<MentorDetailExtras> snap) {
              final bool subscribed = snap.data?.alreadySubscribed ?? false;
              if (subscribed) {
                return PrimaryButton(
                  label: '질문방으로',
                  icon: Icons.forum_outlined,
                  onPressed: () => _goToQuestionRoom(context),
                );
              }
              return PrimaryButton(
                label: '구독하기',
                onPressed: () => openSubscribeWeb(context, mentorId: widget.item.id),
              );
            },
          ),
        ],
      ),
    );
  }

  void _goToQuestionRoom(BuildContext context) {
    // 루트(HomeShell)로 되돌아간 뒤 질문방 탭으로 전환 요청.
    // TabNavigator(app_tabs) → HomeShell 이 수신해 탭 인덱스를 바꾼다(라우터 변경 불필요).
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    TabNavigator.go(AppTab.questionRoom);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item});
  final MentorListItem item;

  @override
  Widget build(BuildContext context) {
    final String? school = item.profile?.schoolLine;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InitialAvatar(name: item.displayName, size: 64),
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
                      style: AppTypography.title,
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
                const SizedBox(height: 4),
                Text(school, style: AppTypography.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 통계: 공개 가능한 항목만 표시한다(평균 답변시간). 없으면 '신규 멘토' 친화 표기.
class _StatsView extends StatelessWidget {
  const _StatsView({required this.extras, required this.loading});
  final MentorDetailExtras extras;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Text('불러오는 중…', style: AppTypography.caption);
    }
    final num? hours = extras.avgResponseHours;
    if (hours == null) {
      return const Text(
        '아직 활동 통계가 쌓이지 않은 신규 멘토예요.',
        style: AppTypography.body,
      );
    }
    final String text =
        hours < 1 ? '평균 답변 1시간 이내' : '평균 답변 약 ${hours.round()}시간';
    return Text(text, style: AppTypography.body);
  }
}

/// 요금제: 가격 '표시'만. 활성 요금제가 없으면 '요금제 문의'(가격 날조 금지).
class _PlansView extends StatelessWidget {
  const _PlansView({required this.plans});
  final List<MentorPlan> plans;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Text('요금제 문의', style: AppTypography.body);
    }
    final List<MentorPlan> sorted = <MentorPlan>[...plans]
      ..sort((MentorPlan a, MentorPlan b) =>
          a.amountCents.compareTo(b.amountCents));
    return Column(
      children: <Widget>[
        for (int i = 0; i < sorted.length; i++) ...<Widget>[
          if (i > 0)
            const Divider(height: 16, color: ColorTokens.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(sorted[i].displayLabel, style: AppTypography.body),
              Text(formatWon(sorted[i].won), style: AppTypography.body),
            ],
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTypography.caption),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
