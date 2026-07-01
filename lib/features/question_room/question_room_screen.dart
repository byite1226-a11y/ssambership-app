import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/entitlement/subscription_summary.dart';
import '../../core/entitlement/weekly_question_usage.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/web_bridge/web_bridge_actions.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/tokens/typography.dart';
import '../../design/widgets/app_card.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/initial_avatar.dart';
import '../../design/widgets/secondary_button.dart';
import '../../design/widgets/status_pill.dart';
import '../../shared/format/formatters.dart';
import 'data/mentor_lookup_repository.dart';
import 'data/models/room.dart';
import 'data/question_room_read_repository.dart';
import 'ui/mentor/mentor_inbox_screen.dart';
import 'ui/mentor_room_home_screen.dart';

/// 질문방 탭(1뎁스). HomeShell 이 AppBar/하단탭을 제공하므로 본문만 구성(자체 Scaffold 없음).
///
/// ★ role 분기:
///   - student → 내 멘토방 목록(S4).
///   - mentor  → 받은 학생 목록(S5, [MentorInboxScreen]).
///   - admin/guest → 차단(이 앱은 학생·멘토 전용).
class QuestionRoomScreen extends StatelessWidget {
  const QuestionRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    switch (AuthService.instance.currentRole) {
      case AppRole.mentor:
        return const MentorInboxScreen();
      case AppRole.student:
        return const _StudentRoomList();
      case AppRole.admin:
      case AppRole.guest:
        return const EmptyState(
          icon: Icons.forum_outlined,
          title: '질문방은 학생·멘토 전용이에요',
          message: '학생 또는 멘토 계정으로 이용해 주세요.',
        );
    }
  }
}

/// 학생용 1뎁스 = 내 멘토방 목록(카카오톡식). (S4)
class _StudentRoomList extends StatefulWidget {
  const _StudentRoomList();

  @override
  State<_StudentRoomList> createState() => _StudentRoomListState();
}

/// 목록 한 행에 필요한 묶음(방 + 멘토 표시명 + 구독 요약 + 주간 사용량).
class _RoomItem {
  const _RoomItem({required this.room, this.mentor, this.sub, this.usage});
  final Room room;
  final MentorPublic? mentor;
  final SubscriptionSummary? sub;

  /// A2: 이 멘토와의 이번 주 질문 사용량(RPC). null = 미조회/실패 → 표시 생략.
  final WeeklyQuestionUsage? usage;

  String get mentorName => mentor?.displayName ?? '멘토';
}

class _StudentRoomListState extends State<_StudentRoomList> {
  final QuestionRoomReadRepository _repo = const QuestionRoomReadRepository();
  final MentorLookupRepository _mentors = const MentorLookupRepository();

  late Future<List<_RoomItem>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_RoomItem>> _load() async {
    final List<Room> rooms = await _repo.myRooms();
    if (rooms.isEmpty) return <_RoomItem>[];
    final String? studentId = SupabaseInit.clientOrNull?.auth.currentUser?.id;
    final Map<String, SubscriptionSummary> subs = studentId == null
        ? <String, SubscriptionSummary>{}
        : await SubscriptionReader.fetchForStudent(
            SupabaseInit.clientOrNull!, studentId);
    final Map<String, MentorPublic> names =
        await _mentors.fetchMany(rooms.map((Room r) => r.mentorId));
    // A2: 멘토별 주간 사용량(RPC). ★ 한도값 재하드코딩 없이 RPC 반환만. 실패는 null(표시 생략).
    final Map<String, WeeklyQuestionUsage?> usageByMentor =
        <String, WeeklyQuestionUsage?>{};
    if (studentId != null) {
      final Set<String> mentorIds =
          rooms.map((Room r) => r.mentorId).toSet();
      await Future.wait(mentorIds.map((String mentorId) async {
        usageByMentor[mentorId] =
            await _repo.weeklyUsage(studentId: studentId, mentorId: mentorId);
      }));
    }
    return rooms
        .map((Room r) => _RoomItem(
              room: r,
              mentor: names[r.mentorId],
              sub: subs[r.mentorId],
              usage: usageByMentor[r.mentorId],
            ))
        .toList();
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            style: AppTypography.body,
            onChanged: (String v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: '멘토 검색',
              prefixIcon: const Icon(Icons.search, color: ColorTokens.muted),
              filled: true,
              fillColor: ColorTokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(child: _list()),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SecondaryButton(
              // 구독 단위는 멘토-학생 쌍 → 문구를 '멘토 구독하기'로(웹 정본 기준).
              label: '멘토 구독하기',
              icon: Icons.add,
              onPressed: () => openSubscribeWeb(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _list() {
    return FutureBuilder<List<_RoomItem>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<_RoomItem>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorView(message: '목록을 불러오지 못했어요.\n${snap.error}');
        }
        final List<_RoomItem> all = snap.data ?? <_RoomItem>[];
        if (all.isEmpty) {
          return const EmptyState(
            icon: Icons.forum_outlined,
            title: '아직 구독한 멘토가 없어요',
            message: '멘토를 구독하면 여기에서 질문할 수 있어요.',
          );
        }
        final List<_RoomItem> items = _query.isEmpty
            ? all
            : all
                .where((_RoomItem it) => it.mentorName.contains(_query))
                .toList();
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: '검색 결과가 없어요',
            message: '다른 이름으로 검색해 보세요.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int i) =>
              _RoomTile(item: items[i], onOpen: () => _open(items[i])),
        );
      },
    );
  }

  Future<void> _open(_RoomItem it) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MentorRoomHomeScreen(
          room: it.room,
          mentorName: it.mentorName,
          sub: it.sub,
        ),
      ),
    );
    if (mounted) _refresh(); // 돌아오면 최신화(새 질문/확인 반영).
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.item, required this.onOpen});
  final _RoomItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final SubscriptionSummary? sub = item.sub;
    // 구독 상태칩·갱신일은 넘칠 수 있어 Wrap 으로 자연스럽게 줄바꿈(정보 유지, 배치만 정돈).
    final String? quotaLabel = item.usage?.planQuotaLabel;
    final List<Widget> meta = <Widget>[
      if (sub != null)
        StatusPill(
          label: sub.isActive ? '구독 중' : '구독 만료',
          tone: sub.isActive ? StatusTone.success : StatusTone.warning,
        ),
      // A2: 주간 잔여("주 N개 질문 · 잔여 X/N", 프리미엄=무제한). RPC 값 있을 때만.
      if (quotaLabel != null)
        Text(quotaLabel, style: AppTypography.caption),
      if (sub?.nextRenewal != null)
        Text(
          '다음 갱신 ${Formatters.shortDate(sub!.nextRenewal!)}',
          style: AppTypography.caption,
        ),
    ];
    return AppCard(
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          InitialAvatar(name: item.mentorName, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 멘토명 + 마지막 활동시각(채팅목록식): 이름과 시각을 한 줄에 정렬.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.mentorName,
                        style: AppTypography.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.relativeKorean(item.room.updatedAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                if (meta.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: meta,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ColorTokens.danger),
        ),
      ),
    );
  }
}
