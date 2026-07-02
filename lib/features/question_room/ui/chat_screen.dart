import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../design/tokens/color_tokens.dart';
import '../data/attachments/attachment_upload.dart';
import '../data/attachments/device_image_picker.dart';
import '../data/models/question_message.dart';
import '../data/models/question_thread.dart';
import '../data/question_room_read_repository.dart';
import '../data/question_room_write_repository.dart';
import '../data/thread_messages_controller.dart';
import '../data/thread_realtime.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/live_message_list.dart';
import 'widgets/thread_status_pill.dart';

/// 채팅(3뎁스). 카카오톡식 말풍선(학생=우측/멘토=좌측) + 하단 입력창.
/// 메시지는 append 전용 — 수정/삭제 없음.
///
/// S6: Realtime 구독으로 새 메시지를 새로고침 없이 즉시 반영(폴백: 전송 후/수동 재조회).
///     첨부는 주입 포트로 이미지 선택→미리보기→업로드(저장소 준비 시 동작).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.thread,
    required this.mentorName,
    this.imagePicker = const DeviceImagePicker(),
    this.uploader = const SupabaseAttachmentUploader(),
    this.realtimeFactory = _defaultRealtime,
  });

  final QuestionThread thread;
  final String mentorName;

  /// 이미지 선택 포트(기본: 미도입 — 인수인계). 테스트에서 fake 주입.
  final ImagePickerPort imagePicker;

  /// 첨부 업로드 포트(기본: 저장소 미준비 — 인수인계).
  final AttachmentUploaderPort uploader;

  /// 스레드 실시간 포트 팩토리(기본: Supabase). 테스트에서 fake 주입.
  final ThreadRealtimePort Function(String threadId) realtimeFactory;

  static ThreadRealtimePort _defaultRealtime(String threadId) =>
      SupabaseThreadRealtime(threadId);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final QuestionRoomReadRepository _read = const QuestionRoomReadRepository();
  final QuestionRoomWriteRepository _write =
      const QuestionRoomWriteRepository();
  final TextEditingController _input = TextEditingController();

  late final ThreadRealtimePort _realtime;
  late ThreadStatus _status; // 실시간 상태 변경(멘토 답변 등)으로 갱신.
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

  /// 스레드 상태 변경(실시간) → 최신 상태 재조회해 상태칩 갱신.
  Future<void> _onThreadUpdate() async {
    try {
      final QuestionThread? t = await _read.threadById(widget.thread.id);
      if (t != null && mounted) setState(() => _status = t.status);
    } catch (_) {
      // 무시 — 상태칩은 다음 갱신에서 반영.
    }
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

  /// 폴백 재조회(Realtime 미설정 시 수동 새로고침 = 상대 메시지 반영).
  Future<void> _refresh() async {
    final ThreadMessagesController? ctrl = _messages;
    if (ctrl == null) return;
    try {
      final List<QuestionMessage> msgs = await _read.messages(widget.thread.id);
      ctrl.resetTo(msgs);
    } catch (_) {
      // 조용히 무시 — 기존 목록 유지.
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
        _messages?.add(sent); // 낙관적 반영(실시간과 중복돼도 무시됨).
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
      // 저장소 미준비(버킷 없음) → 안내만(골격). 텍스트는 이미 전송됨.
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
      await _refresh(); // 첨부 반영.
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
    if (img == null) return; // 취소.
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.thread.title?.trim().isNotEmpty == true
              ? widget.thread.title!.trim()
              : '질문',
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
            hintText: '메시지 입력',
            sending: _sending,
            onSend: _send,
            onAttach: _attach,
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
      emptyHint: '첫 메시지를 남겨보세요.',
      onThreadUpdate: _onThreadUpdate,
    );
  }
}
