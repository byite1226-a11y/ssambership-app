import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../shared/format/formatters.dart';
import '../data/models/question_message.dart';
import '../data/models/question_thread.dart';
import '../data/question_room_read_repository.dart';
import '../data/question_room_write_repository.dart';
import 'widgets/thread_status_pill.dart';

/// 채팅(3뎁스). 카카오톡식 말풍선(학생=우측/멘토=좌측) + 하단 입력창.
/// 메시지는 append 전용 — 수정/삭제 없음.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.thread, required this.mentorName});

  final QuestionThread thread;
  final String mentorName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final QuestionRoomReadRepository _read = const QuestionRoomReadRepository();
  final QuestionRoomWriteRepository _write =
      const QuestionRoomWriteRepository();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late Future<List<QuestionMessage>> _future;
  bool _sending = false;

  String? get _uid => SupabaseInit.clientOrNull?.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.thread.title?.trim().isNotEmpty == true
              ? widget.thread.title!.trim()
              : '질문',
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: ThreadStatusPill(status: widget.thread.status)),
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
                    child: Text('첫 메시지를 남겨보세요.',
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
                    return _Bubble(message: m, mine: mine);
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
                  hintText: '메시지 입력',
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
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final QuestionMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final Color bg = mine ? ColorTokens.accent : ColorTokens.surface;
    final Color fg = mine ? ColorTokens.page : ColorTokens.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (mine)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(Formatters.hourMinute(message.createdAt),
                  style: AppTypography.caption),
            ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: mine
                    ? null
                    : Border.all(color: ColorTokens.border),
              ),
              child: Text(message.body,
                  style: AppTypography.body.copyWith(color: fg)),
            ),
          ),
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(Formatters.hourMinute(message.createdAt),
                  style: AppTypography.caption),
            ),
        ],
      ),
    );
  }
}
