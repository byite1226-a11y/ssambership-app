import 'package:flutter/material.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../data/attachments/attachment_upload.dart';
import '../../data/attachments/attachment_url_resolver.dart';
import '../../data/attachments/device_image_picker.dart';
import '../../data/models/question_attachment.dart';
import '../../data/models/question_message.dart';
import '../../data/models/question_thread.dart';
import '../../data/question_room_read_repository.dart';
import '../../data/question_room_write_repository.dart';
import '../../data/thread_messages_controller.dart';
import '../../data/thread_realtime.dart';
import '../attachment_viewer_screen.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/scan_source_sheet.dart';
import '../widgets/live_message_list.dart';
import '../widgets/thread_status_pill.dart';
import '../../../../core/scan/image_downscaler.dart';
import '../../../../core/scan/scan_source_picker.dart';
import '../../../../core/scan/pdf_rasterizer.dart';
import '../../../../core/scan/widgets/scan_pick_expander.dart';
import '../../../../shared/errors/friendly_error.dart';

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
    this.scanPicker = const DeviceScanSourcePicker(),
    this.pdfRasterizer = const PdfxRasterizer(),
    this.uploader = const SupabaseAttachmentUploader(),
    this.realtimeFactory = _defaultRealtime,
  });

  final QuestionThread thread;
  final String studentName;
  final ImagePickerPort imagePicker;

  /// 스캔 소스 포트(S16: 촬영·파일). 테스트에서 fake 주입.
  final ScanSourcePort scanPicker;

  /// PDF 래스터라이저 포트(S19: 파일 소스 PDF → 페이지 선택). fake 주입 지점.
  final PdfRasterizerPort pdfRasterizer;
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

  /// 첨부 이미지 서명 URL 리졸버(만료 전 캐시 재사용).
  final AttachmentUrlResolver _resolver = AttachmentUrlResolver.supabase();
  List<QuestionAttachment> _attachments = <QuestionAttachment>[];

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
      final List<QuestionAttachment> atts = await _loadAttachments();
      if (!mounted) return;
      setState(() {
        _messages = ThreadMessagesController(msgs);
        _attachments = atts;
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

  /// 첨부 조회는 best-effort — 실패해도 대화는 막지 않는다(빈 목록 폴백).
  Future<List<QuestionAttachment>> _loadAttachments() async {
    try {
      return await _read.attachments(widget.thread.id);
    } catch (_) {
      return const <QuestionAttachment>[];
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
    final List<QuestionAttachment> atts = await _loadAttachments();
    if (mounted) setState(() => _attachments = atts);
  }

  /// 이미지 첨부 탭 → 전체화면 뷰어. 주석이 전송되면 목록 새로고침.
  Future<void> _openImage(QuestionAttachment a) async {
    final bool? refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => AttachmentViewerScreen(
          attachment: a,
          roomId: widget.thread.roomId,
          threadId: widget.thread.id,
          resolver: _resolver,
        ),
      ),
    );
    if (refreshed == true && mounted) await _refresh();
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
      _showError('전송에 실패했어요. ${friendlyError(e)}');
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
      _showError('이미지 첨부에 실패했어요. ${friendlyError(e)}');
    }
  }

  /// 첨부(S16/S19): 소스 시트 → 선택 → (PDF 면 페이지 선택) → 검증 → 미리보기.
  /// 갤러리는 기존 imagePicker 포트(하위호환), 촬영·파일은 scanPicker 포트.
  /// PDF 분기는 expandScanPick(소스 계층)이 담당 — 이 화면은 모른다.
  Future<void> _attach() async {
    final ScanSource? source = await showScanSourceSheet(context);
    if (source == null || !mounted) return; // 시트 취소 — 무동작.
    try {
      final PickedImage? picked = source == ScanSource.gallery
          ? await widget.imagePicker.pickImage()
          : await widget.scanPicker.pick(source);
      if (!mounted) return;
      final List<PickedImage> images = await expandScanPick(
        context,
        picked: picked,
        rasterizer: widget.pdfRasterizer,
        maxCount: 1, // 대기 슬롯 1(전송 전 미리보기 1장).
      );
      if (images.isNotEmpty) await _acceptPicked(images.first);
    } catch (e) {
      // PDF 폴백 안내(AppError) 포함 — 원문 비노출 규약.
      _showError(friendlyError(e));
    }
  }

  /// 선택 결과 공통 처리: 5MB 초과 리사이즈(§6-4) → 검증 → 미리보기 세팅.
  Future<void> _acceptPicked(PickedImage picked) async {
    final PickedImage img = await downscaleIfOversized(picked);
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
                style: AppType.caption.copyWith(color: ColorTokens.muted)),
            Text(title,
                style: AppType.body,
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
          child: Text('대화를 불러오지 못했어요.\n${friendlyError(_loadError!)}',
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
      attachments: _attachments,
      resolver: _resolver,
      onOpenImage: _openImage,
    );
  }
}
