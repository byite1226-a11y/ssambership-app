import 'package:flutter/material.dart';

import '../../../../design/tokens/typography.dart';
import '../../data/models/question_message.dart';
import '../../data/thread_messages_controller.dart';
import '../../data/thread_realtime.dart';
import 'message_bubble.dart';

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
  });

  final ThreadMessagesController controller;
  final ThreadRealtimePort realtime;
  final String? currentUid;
  final String emptyHint;

  /// 스레드 상태 변경(pending→answered 등) 수신 시 부모에 알림(상태칩 갱신용).
  final VoidCallback? onThreadUpdate;

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
    final List<QuestionMessage> messages = widget.controller.items;
    if (messages.isEmpty) {
      return Center(
        child: Text(widget.emptyHint, style: AppTypography.caption),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int i) {
        final QuestionMessage m = messages[i];
        final bool mine =
            widget.currentUid != null && m.authorId == widget.currentUid;
        return MessageBubble(message: m, mine: mine);
      },
    );
  }
}
