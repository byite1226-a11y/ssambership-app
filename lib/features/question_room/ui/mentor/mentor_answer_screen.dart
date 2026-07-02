import 'package:flutter/material.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../data/attachments/attachment_upload.dart';
import '../../data/attachments/device_image_picker.dart';
import '../../data/models/question_message.dart';
import '../../data/models/question_thread.dart';
import '../../data/question_room_read_repository.dart';
import '../../data/question_room_write_repository.dart';
import '../../data/thread_messages_controller.dart';
import '../../data/thread_realtime.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/live_message_list.dart';
import '../widgets/thread_status_pill.dart';

/// 멘토 답변 화면(3뎁스). 학생 채팅의 거울상 — 멘토=우측 / 학생=좌측(MessageBubble 자동 처리).
///
/// ★ 멘토가 메시지를 보내면(append) '답변 대기(pending)' → '진행 중(answered)' 전이("답변 전송").
///   학생이 확인하면 '답변 완료(confirmed)' — 역할 분리. 메시지는 append 전용.
///
/// S6: Realtime 구독으로 학생 메시지를 즉시 반영(폴백: 전송 후/수동 재조회).
///     첨부는 주입 포트(저장소 준비 시 동작).
class MentorAnswerScreen extends StatefulWidget {
  const MentorAnswerScreen({
    super.key,
    required this.thread,
    required this.studentName,
    this.imagePicker = const DeviceImagePicker(),
    this.uploader = const SupabaseAttachmentUploader(),
    this.realtimeFactory = _defaultRealtime,
  });

  final QuestionThread thread;
  final String studentName;
  final ImagePickerPort imagePicker;
  final AttachmentUploaderPort uploader;
  final ThreadRealtimePort Function(String threadId) realtimeFactory;

  static ThreadRealtimePort _defaultRealtime(String threadId) =>
      SupabaseThreadRealtime(threadId);

  @override
  State<MentorAnswerScreen> createState() => _MentorAnswerScreenState();
}

class _MentorAnswerScreenState extends State<MentorAnswerScreen> {
  final QuestionRoomReadRepository _read = const QuestionRoomReadRepository();
  final QuestionRoomWriteRepository _write =
      const QuestionRoomWriteRepository();
  final TextEditingController _input = TextEditingController();

  late final ThreadRealtimePort _realtime;
  late ThreadStatus _status;
  ThreadMessagesController? _messages;
  bool _loading = true;
  Object? _loadError;
  bool _sending = false;
  PickedImage? _pending;

  String? get _uid => SupabaseInit.clientOrNull?.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _status = widget.thread.status;
    _realtime = widget.realtimeFactory(widget.thread.id);
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _messages?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<QuestionMessage> msgs = await _read.messages(widget.thread.id);
      if (!mounted) return;
      setState(() {
        _messages = ThreadMessagesController(msgs);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final ThreadMessagesController? ctrl = _messages;
    if (ctrl == null) return;
    try {
      final List<QuestionMessage> msgs = await _read.messages(widget.thread.id);
      ctrl.resetTo(msgs);
    } catch (_) {
      // 무시 — 기존 목록 유지.
    }
  }

  Future<void> _onThreadUpdate() async {
    try {
      final QuestionThread? t = await _read.threadById(widget.thread.id);
      if (t != null && mounted) setState(() => _status = t.status);
    } catch (_) {
      // 무시.
    }
  }

  Future<void> _send() async {
    final String body = _input.text.trim();
    final PickedImage? pending = _pending;
    if ((body.isEmpty && pending == null) || _sending) return;
    setState(() => _sending = true);
    try {
      QuestionMessage? sent;
      if (body.isNotEmpty) {
        sent = await _write.appendMessage(threadId: widget.thread.id, body: body);
        _input.clear();
        _messages?.add(sent);
        // 답변 전송 = 첫 답변이면 '답변 대기' → '진행 중' 전이.
        if (_status == ThreadStatus.pending) {
          try {
            final QuestionThread updated =
                await _write.markThreadAnswered(widget.thread.id);
            if (mounted) setState(() => _status = updated.status);
          } catch (_) {
            // 전이 실패해도 메시지는 이미 전송됨 — 상태는 다음 갱신에서 반영.
          }
        }
      }
      if (pending != null) {
        await _uploadPending(pending, messageId: sent?.id);
      }
    } catch (e) {
      _showError('전송에 실패했어요. ($e)');
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _pending = null;
        });
      }
    }
  }

  Future<void> _uploadPending(PickedImage image, {String? messageId}) async {
    if (!widget.uploader.isReady) {
      _showError('이미지 첨부는 준비 중이에요. (저장소 설정 인수인계)');
      return;
    }
    try {
      await widget.uploader.upload(
        roomId: widget.thread.roomId,
        threadId: widget.thread.id,
        messageId: messageId,
        image: image,
      );
      await _refresh();
    } catch (e) {
      _showError('이미지 첨부에 실패했어요. ($e)');
    }
  }

  Future<void> _attach() async {
    if (!widget.imagePicker.isAvailable) {
      _showError('이미지 선택 기능은 준비 중이에요. (image_picker 인수인계)');
      return;
    }
    final PickedImage? img = await widget.imagePicker.pickImage();
    if (img == null) return;
    final String? invalid = validatePickedImage(img);
    if (invalid != null) {
      _showError(invalid);
      return;
    }
    if (mounted) setState(() => _pending = img);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
                style: AppTypography.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _refresh,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: ThreadStatusPill(status: _status)),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: _list()),
          ChatInputBar(
            controller: _input,
            hintText: '답변 입력',
            sending: _sending,
            onSend: _send,
            onAttach: _attach,
            sendTooltip: '답변 전송',
            pendingImage: _pending,
            onRemovePending: () => setState(() => _pending = null),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('대화를 불러오지 못했어요.\n$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColorTokens.danger)),
        ),
      );
    }
    return LiveMessageList(
      controller: _messages!,
      realtime: _realtime,
      currentUid: _uid,
      emptyHint: '학생의 질문에 첫 답변을 남겨보세요.',
      onThreadUpdate: _onThreadUpdate,
    );
  }
}
