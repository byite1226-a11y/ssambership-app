import 'package:flutter/material.dart';

import '../../../../design/widgets/status_pill.dart';
import '../../../../shared/labels/question_room_labels.dart';
import '../../data/models/question_thread.dart';

/// 스레드 상태 칩. 라벨은 웹 기준(답변 대기/진행 중/답변 완료),
/// 색은 기존 시맨틱 토큰만(pending=warning, answered=accent, confirmed=success).
class ThreadStatusPill extends StatelessWidget {
  const ThreadStatusPill({super.key, required this.status});

  final ThreadStatus status;

  static StatusTone toneFor(ThreadStatus s) {
    switch (s) {
      case ThreadStatus.pending:
        return StatusTone.warning;
      case ThreadStatus.answered:
      case ThreadStatus.open:
        return StatusTone.info;
      case ThreadStatus.confirmed:
        return StatusTone.success;
      case ThreadStatus.closed:
      case ThreadStatus.archived:
      case ThreadStatus.unknown:
        return StatusTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: QuestionRoomLabels.threadStatus(status),
      tone: toneFor(status),
    );
  }
}
