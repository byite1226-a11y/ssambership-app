import 'package:flutter/material.dart';

import '../../../core/commerce/commerce_policy.dart';
import '../../../core/entitlement/subscription_summary.dart';
import '../../../core/entitlement/weekly_question_usage.dart';
import '../../../design/role_accent.dart';
import '../../../design/spacing_tokens.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/typography_tokens.dart';
import '../../../design/widgets/primary_button.dart';
import '../../../design/widgets/secondary_button.dart';
import '../data/models/question_thread.dart';
import '../data/models/room.dart';
import '../data/question_room_read_repository.dart';
import '../data/question_room_write_repository.dart';
import 'chat_screen.dart';
import 'connection_notes_screen.dart';
import 'new_question_screen.dart';
import '../../../shared/widgets/commerce_notice_card.dart';
import 'widgets/thread_card.dart';

/// 질문 영역(3뎁스). 스레드 카드 목록(최신순) + 새 질문 + 연결노트 플로팅.
class QuestionListScreen extends StatefulWidget {
  const QuestionListScreen({
    super.key,
    required this.room,
    required this.mentorName,
    this.sub,
  });

  final Room room;
  final String mentorName;
  final SubscriptionSummary? sub;

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  final QuestionRoomReadRepository _read = const QuestionRoomReadRepository();
  final QuestionRoomWriteRepository _write =
      const QuestionRoomWriteRepository();

  late Future<List<QuestionThread>> _future;
  bool _busy = false;

  /// A2: 이번 주 질문 사용량(잔여 표시용). null = 미조회/실패 → 표시 생략.
  WeeklyQuestionUsage? _usage;

  @override
  void initState() {
    super.initState();
    _future = _read.threads(widget.room.id);
    _loadUsage();
  }

  void _refresh() {
    setState(() => _future = _read.threads(widget.room.id));
    _loadUsage();
  }

  /// 주간 사용량 조회(읽기전용). 실패해도 화면 흐름은 막지 않는다.
  Future<void> _loadUsage() async {
    final WeeklyQuestionUsage? u = await _read.weeklyUsage(
      studentId: widget.room.studentId,
      mentorId: widget.room.mentorId,
    );
    if (mounted) setState(() => _usage = u);
  }

  bool get _canAsk => widget.sub?.canAsk ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 연결노트는 상단 액션으로 둔다 — 하단 '질문하기' 바와 겹치지 않도록(플로팅 제거).
      appBar: AppBar(
        title: const Text('질문 / 답변'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _openNotes,
            icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
            label: const Text('연결노트'),
            style: TextButton.styleFrom(foregroundColor: AppAccent.of(context).accent),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List<QuestionThread>>(
              future: _future,
              builder: (BuildContext context,
                  AsyncSnapshot<List<QuestionThread>> snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('질문을 불러오지 못했어요.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ColorTokens.danger)),
                    ),
                  );
                }
                final List<QuestionThread> threads =
                    snap.data ?? <QuestionThread>[];
                if (threads.isEmpty) {
                  return const _EmptyQuestions();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.cardGap),
                  itemBuilder: (BuildContext context, int i) => ThreadCard(
                    thread: threads[i],
                    onOpen: () => _openChat(threads[i]),
                    bottomAction: threads[i].status == ThreadStatus.answered
                        ? SecondaryButton(
                            label: '답변 확인 완료',
                            onPressed: () => _confirm(threads[i]),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          _askBar(),
        ],
      ),
    );
  }

  Widget _askBar() {
    final String? remaining = _usage?.remainingLabel;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_canAsk) ...<Widget>[
              if (remaining != null) ...<Widget>[
                Text(remaining,
                    style: AppType.caption, textAlign: TextAlign.center),
                const SizedBox(height: 8),
              ],
              PrimaryButton(
                label: '+ 새로운 질문하기',
                onPressed: _busy ? null : _openNewQuestion,
              ),
            ] else if (widget.sub?.isActive == true) ...<Widget>[
              // 구독 중인데 이번 주 소진 — 안내만(구매 유도 아님).
              const Text(
                '이번 주 질문을 모두 사용했어요.',
                style: AppType.caption,
                textAlign: TextAlign.center,
              ),
            ] else ...<Widget>[
              // 커머스 제로: 구매 유도(웹에서 구독) 버튼 제거 → 비상호작용 안내.
              const CommerceNoticeCard(text: kSubscribeNoticeText),
            ],
            // 연결노트 발견성: appBar 액션과 동일 라우트를 하단에도 노출(구독 여부 무관).
            const SizedBox(height: 8),
            SecondaryButton(
              label: '연결노트',
              icon: Icons.sticky_note_2_rounded,
              onPressed: _openNotes,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNewQuestion() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NewQuestionScreen(room: widget.room),
      ),
    );
    if (created == true && mounted) _refresh();
  }

  Future<void> _openChat(QuestionThread t) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(thread: t, mentorName: widget.mentorName),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _openNotes() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConnectionNotesScreen(
          room: widget.room,
          mentorName: widget.mentorName,
        ),
      ),
    );
  }

  Future<void> _confirm(QuestionThread t) async {
    setState(() => _busy = true);
    try {
      await _write.confirmThread(t.id);
      if (mounted) _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('확인 처리에 실패했어요. ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// 질문 0개 빈 상태 — 웹 기준 3단계 안내.
/// ★ 질문 CTA 버튼은 두지 않는다 — 하단 고정 바(_askBar)의 '+ 새로운 질문하기' 하나로 통일(중복 제거).
class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 8),
        const Icon(Icons.forum_rounded, size: 44, color: ColorTokens.muted),
        const SizedBox(height: 14),
        Text('이 멘토에게 첫 질문을 남겨보세요',
            style: AppType.title, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        const _Step(n: '1', text: '과목·단원 고르기 (선택)'),
        const _Step(n: '2', text: '궁금한 점 질문 (사진·파일 첨부 가능)'),
        const _Step(n: '3', text: '답변 확인'),
        const SizedBox(height: 14),
        Text('연결노트로 기록이 쌓여요',
            style: AppType.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});
  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          InitialAvatarLike(label: n),
          const SizedBox(width: 10),
          Flexible(child: Text(text, style: AppType.body)),
        ],
      ),
    );
  }
}

/// 단계 번호 동그라미(기존 토큰만, 새 색 없음).
class InitialAvatarLike extends StatelessWidget {
  const InitialAvatarLike({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: ColorTokens.elevated,
        shape: BoxShape.circle,
      ),
      child: Text(label,
          style: TextStyle(
              color: AppAccent.of(context).accent, fontWeight: FontWeight.w800)),
    );
  }
}
