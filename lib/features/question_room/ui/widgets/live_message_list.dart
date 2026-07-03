import 'package:flutter/material.dart';

import '../../../../design/spacing_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../data/attachments/attachment_url_resolver.dart';
import '../../data/models/question_attachment.dart';
import '../../data/models/question_message.dart';
import '../../data/thread_messages_controller.dart';
import '../../data/thread_realtime.dart';
import 'message_bubble.dart';
import 'message_image_attachment.dart';

/// 실시간 메시지 목록. [controller] 를 렌더하고 [realtime] 구독을 시작/정리한다.
///
/// - 실시간 insert → controller.add → 새로고침 없이 즉시 목록에 추가(맨 아래로 스크롤).
/// - 내가 보낸 메시지도 화면(부모)이 같은 controller 에 add 하므로 함께 반영된다(중복 무시).
/// - Realtime 이 꺼져 있으면(publication 미포함) 콜백이 안 올 뿐, 부모의 재조회 폴백으로 동작.
class LiveMessageList extends StatefulWidget {
  const LiveMessageList({
    super.key,
    required this.controller,
    required this.realtime,
    required this.currentUid,
    this.emptyHint = '첫 메시지를 남겨보세요.',
    this.onThreadUpdate,
    this.attachments = const <QuestionAttachment>[],
    this.resolver,
    this.onOpenImage,
  });

  final ThreadMessagesController controller;
  final ThreadRealtimePort realtime;
  final String? currentUid;
  final String emptyHint;

  /// 스레드 상태 변경(pending→answered 등) 수신 시 부모에 알림(상태칩 갱신용).
  final VoidCallback? onThreadUpdate;

  /// 스레드 첨부(이미지만 표시). [resolver] 가 있어야 실제로 렌더한다.
  final List<QuestionAttachment> attachments;

  /// 서명 URL 리졸버(주입). null 이면 첨부 미표시(기존 동작 유지·하위호환).
  final AttachmentUrlResolver? resolver;

  /// 이미지 첨부 탭 시(전체화면 뷰어 진입 등).
  final void Function(QuestionAttachment)? onOpenImage;

  @override
  State<LiveMessageList> createState() => _LiveMessageListState();
}

class _LiveMessageListState extends State<LiveMessageList> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.realtime.start(
      onMessageInsert: (QuestionMessage m) => widget.controller.add(m),
      onThreadUpdate: widget.onThreadUpdate,
    );
    _jumpToEndSoon();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    // 구독 정리(누수 금지). 포트는 이 위젯이 소유.
    widget.realtime.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _jumpToEndSoon();
  }

  void _jumpToEndSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<_Row> rows = _buildRows();
    if (rows.isEmpty) {
      return Center(
        child: Text(widget.emptyHint, style: AppType.caption),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.s16),
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int i) => rows[i].child,
    );
  }

  /// 메시지 + 이미지 첨부를 시간순으로 병합한다.
  /// - 메시지에 연결된(message_id 일치) 이미지 첨부는 그 말풍선 안에 썸네일로.
  /// - 연결이 없는(예: 이미지-only 전송·주석 평탄화) 이미지 첨부는 독립 행으로.
  List<_Row> _buildRows() {
    final List<QuestionMessage> messages = widget.controller.items;
    final AttachmentUrlResolver? resolver = widget.resolver;

    final List<QuestionAttachment> images = resolver == null
        ? const <QuestionAttachment>[]
        : widget.attachments
            .where((QuestionAttachment a) => isImageAttachment(a.mimeType))
            .toList();
    final Set<String> msgIds =
        messages.map((QuestionMessage m) => m.id).toSet();
    final Map<String, List<QuestionAttachment>> linked =
        <String, List<QuestionAttachment>>{};
    final List<QuestionAttachment> standalone = <QuestionAttachment>[];
    for (final QuestionAttachment a in images) {
      final String? mid = a.messageId;
      if (mid != null && msgIds.contains(mid)) {
        linked.putIfAbsent(mid, () => <QuestionAttachment>[]).add(a);
      } else {
        standalone.add(a);
      }
    }

    final List<_Row> rows = <_Row>[];
    for (final QuestionMessage m in messages) {
      final bool mine =
          widget.currentUid != null && m.authorId == widget.currentUid;
      final List<Widget> thumbs = <Widget>[
        for (final QuestionAttachment a in linked[m.id] ?? const <QuestionAttachment>[])
          MessageImageAttachment(
            attachment: a,
            resolver: resolver!,
            onOpen: () => widget.onOpenImage?.call(a),
          ),
      ];
      rows.add(_Row(
        m.createdAt,
        MessageBubble(message: m, mine: mine, attachments: thumbs),
      ));
    }
    for (final QuestionAttachment a in standalone) {
      rows.add(_Row(a.createdAt, _standaloneImage(a, resolver!)));
    }
    rows.sort((_Row x, _Row y) => x.time.compareTo(y.time));
    return rows;
  }

  Widget _standaloneImage(QuestionAttachment a, AttachmentUrlResolver resolver) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.center,
        child: MessageImageAttachment(
          attachment: a,
          resolver: resolver,
          onOpen: () => widget.onOpenImage?.call(a),
          size: 220,
        ),
      ),
    );
  }
}

/// 시간순 병합용 행(메시지 말풍선 or 독립 이미지).
class _Row {
  const _Row(this.time, this.child);
  final DateTime time;
  final Widget child;
}
