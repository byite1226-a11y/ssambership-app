import 'package:flutter/material.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../data/models/question_message.dart';
import '../../data/models/question_thread.dart';
import '../../data/question_room_read_repository.dart';
import '../../data/question_room_write_repository.dart';
import '../widgets/message_bubble.dart';
import '../widgets/thread_status_pill.dart';

/// 멘토 답변 화면(3뎁스). 학생 채팅의 거울상 — 멘토=우측 / 학생=좌측(MessageBubble가 자동 처리).
///
/// ★ 멘토가 메시지를 보내면(append) '답변 대기(pending)' 스레드는 '진행 중(answered)'으로 전이된다.
///   = "답변 전송". (학생이 확인하면 '답변 완료(confirmed)' — 역할이 분리돼 있다.)
///   메시지는 append 전용(수정/삭제 없음).
class MentorAnswerScreen extends StatefulWidget {
  const MentorAnswerScreen({
    super.key,
    required this.thread,
    required this.studentName,
  });

  final QuestionThread thread;
  final String studentName;

  @override
  State<MentorAnswerScreen> createState() => _MentorAnswerScreenState();
}

class _MentorAnswerScreenState extends State<MentorAnswerScreen> {
  final QuestionRoomReadRepository _read = const QuestionRoomReadRepository();
  final QuestionRoomWriteRepository _write =
      const QuestionRoomWriteRepository();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late Future<List<QuestionMessage>> _future;
  late ThreadStatus _status; // 전송에 따라 갱신(거울상 목록에서 즉시 반영)
  bool _sending = false;

  String? get _uid => SupabaseInit.clientOrNull?.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _status = widget.thread.status;
    _future = _read.messages(widget.thread.id);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final Future<List<QuestionMessage>> f = _read.messages(widget.thread.id);
    setState(() => _future = f);
    await f;
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final String body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _write.appendMessage(threadId: widget.thread.id, body: body);
      _input.clear();
      // 답변 전송 = 첫 답변이면 '답변 대기' → '진행 중' 전이.
      if (_status == ThreadStatus.pending) {
        try {
          final QuestionThread updated =
              await _write.markThreadAnswered(widget.thread.id);
          if (mounted) setState(() => _status = updated.status);
        } catch (_) {
          // 전이 실패해도 메시지는 이미 전송됨 — 상태만 다음 새로고침에서 반영.
        }
      }
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송에 실패했어요. ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _attachNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('사진·파일 첨부는 곧 지원돼요. (준비 중)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.thread.title?.trim().isNotEmpty == true
        ? widget.thread.title!.trim()
        : '질문';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(widget.studentName,
                style: AppTypography.caption.copyWith(color: ColorTokens.muted)),
            Text(title,
                style: AppTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: ThreadStatusPill(status: _status)),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List<QuestionMessage>>(
              future: _future,
              builder: (BuildContext context,
                  AsyncSnapshot<List<QuestionMessage>> snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('대화를 불러오지 못했어요.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ColorTokens.danger)),
                    ),
                  );
                }
                final List<QuestionMessage> messages =
                    snap.data ?? <QuestionMessage>[];
                _jumpToEnd();
                if (messages.isEmpty) {
                  return Center(
                    child: Text('학생의 질문에 첫 답변을 남겨보세요.',
                        style: AppTypography.caption),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int i) {
                    final QuestionMessage m = messages[i];
                    final bool mine = _uid != null && m.authorId == _uid;
                    return MessageBubble(message: m, mine: mine);
                  },
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: ColorTokens.surface,
          border: Border(top: BorderSide(color: ColorTokens.border)),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.attach_file, color: ColorTokens.muted),
              onPressed: _attachNotice,
            ),
            Expanded(
              child: TextField(
                controller: _input,
                style: AppTypography.body,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: '답변 입력',
                  filled: true,
                  fillColor: ColorTokens.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: _sending ? ColorTokens.muted : ColorTokens.accent,
              ),
              tooltip: '답변 전송',
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
