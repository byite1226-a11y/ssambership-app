import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/entitlement/subscription_summary.dart';
import '../../core/supabase/supabase_client.dart';
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
import 'ui/mentor_room_home_screen.dart';
import 'ui/widgets/subscribe_web.dart';

/// 질문방 탭(1뎁스) = 내 멘토방 목록. HomeShell 이 AppBar/하단탭을 제공하므로
/// 이 화면은 본문만 구성한다(자체 Scaffold 없음).
class QuestionRoomScreen extends StatefulWidget {
  const QuestionRoomScreen({super.key});

  @override
  State<QuestionRoomScreen> createState() => _QuestionRoomScreenState();
}

/// 목록 한 행에 필요한 묶음(방 + 멘토 표시명 + 구독 요약).
class _RoomItem {
  const _RoomItem({required this.room, this.mentor, this.sub});
  final Room room;
  final MentorPublic? mentor;
  final SubscriptionSummary? sub;

  String get mentorName => mentor?.displayName ?? '멘토';
}

class _QuestionRoomScreenState extends State<QuestionRoomScreen> {
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
    return rooms
        .map((Room r) => _RoomItem(
              room: r,
              mentor: names[r.mentorId],
              sub: subs[r.mentorId],
            ))
        .toList();
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    // 멘토 계정 방어 — 멘토용 화면은 S5. 학생 질문방 목록을 멘토에게 띄우지 않는다.
    if (AuthService.instance.currentRole == AppRole.mentor) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: '멘토 화면은 준비 중이에요',
        message: '멘토용 질문방은 곧 제공돼요.',
      );
    }

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
              label: '질문방 구독하기',
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    return AppCard(
      onTap: onOpen,
      child: Row(
        children: <Widget>[
          InitialAvatar(name: item.mentorName, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.mentorName, style: AppTypography.body),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    if (sub != null)
                      StatusPill(
                        label: sub.isActive ? '구독 중' : '구독 만료',
                        tone: sub.isActive
                            ? StatusTone.success
                            : StatusTone.warning,
                      ),
                    if (sub?.nextRenewal != null) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        '다음 갱신 ${Formatters.shortDate(sub!.nextRenewal!)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.relativeKorean(item.room.updatedAt),
            style: AppTypography.caption,
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
