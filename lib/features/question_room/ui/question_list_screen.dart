import 'package:flutter/material.dart';

import '../../../core/entitlement/subscription_summary.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/app_badge.dart';
import '../../../design/widgets/app_card.dart';
import '../../../design/widgets/primary_button.dart';
import '../../../design/widgets/secondary_button.dart';
import '../../../data/mappings/subject_labels.dart';
import '../../../shared/format/formatters.dart';
import '../data/models/question_thread.dart';
import '../data/models/room.dart';
import '../data/question_room_read_repository.dart';
import '../data/question_room_write_repository.dart';
import 'chat_screen.dart';
import 'connection_notes_screen.dart';
import 'new_question_screen.dart';
import 'widgets/subscribe_web.dart';
import 'widgets/thread_status_pill.dart';

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

  @override
  void initState() {
    super.initState();
    _future = _read.threads(widget.room.id);
  }

  void _refresh() => setState(() => _future = _read.threads(widget.room.id));

  bool get _canAsk => widget.sub?.canAsk ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('질문 / 답변')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNotes,
        icon: const Icon(Icons.sticky_note_2_outlined),
        label: const Text('연결노트'),
        backgroundColor: ColorTokens.surface,
        foregroundColor: ColorTokens.accent,
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
                  return _EmptyQuestions(
                    canAsk: _canAsk,
                    onAsk: _openNewQuestion,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int i) => _ThreadCard(
                    thread: threads[i],
                    onOpen: () => _openChat(threads[i]),
                    onConfirm: threads[i].status == ThreadStatus.answered
                        ? () => _confirm(threads[i])
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _canAsk
            ? PrimaryButton(
                label: '+ 질문하기',
                onPressed: _busy ? null : _openNewQuestion,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.sub?.isActive == true
                        ? '이번 주 질문을 모두 사용했어요.'
                        : '구독이 필요해요. 웹에서 구독하면 질문할 수 있어요.',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: '웹에서 구독',
                    onPressed: () => openSubscribeWeb(context),
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

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.thread,
    required this.onOpen,
    this.onConfirm,
  });

  final QuestionThread thread;
  final VoidCallback onOpen;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  thread.title?.trim().isNotEmpty == true
                      ? thread.title!.trim()
                      : '(제목 없음)',
                  style: AppTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ThreadStatusPill(status: thread.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              AppBadge(label: subjectLabel(thread.subject), tinted: true),
              if (thread.isWrongAnswer) ...<Widget>[
                const SizedBox(width: 6),
                const AppBadge(label: '오답노트'),
              ],
              const Spacer(),
              Text(
                Formatters.relativeKorean(thread.updatedAt),
                style: AppTypography.caption,
              ),
            ],
          ),
          if (onConfirm != null) ...<Widget>[
            const SizedBox(height: 12),
            SecondaryButton(label: '답변 확인 완료', onPressed: onConfirm),
          ],
        ],
      ),
    );
  }
}

/// 질문 0개 빈 상태 — 웹 기준 3단계 안내.
class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions({required this.canAsk, required this.onAsk});
  final bool canAsk;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 8),
        const Icon(Icons.forum_outlined, size: 44, color: ColorTokens.muted),
        const SizedBox(height: 14),
        Text('이 멘토에게 첫 질문을 남겨보세요',
            style: AppTypography.title, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        const _Step(n: '1', text: '과목·단원 고르기 (선택)'),
        const _Step(n: '2', text: '궁금한 점 질문 (사진·파일 첨부 가능)'),
        const _Step(n: '3', text: '답변 확인'),
        const SizedBox(height: 14),
        Text('연결노트로 기록이 쌓여요',
            style: AppTypography.caption, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        if (canAsk)
          PrimaryButton(label: '+ 새로운 질문하기', onPressed: onAsk, expand: false),
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
          Flexible(child: Text(text, style: AppTypography.body)),
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
          style: const TextStyle(
              color: ColorTokens.accent, fontWeight: FontWeight.w800)),
    );
  }
}
