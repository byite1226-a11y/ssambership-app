import 'models/question_thread.dart';

/// 한 방(학생)의 스레드 상태 집계. 멘토 받은-학생 목록/학생방 홈이 공유한다.
///
/// ★ 라벨 매핑(웹 기준)과 일치: pending=답변 대기, answered/open=진행 중, confirmed=답변 완료.
///   '안읽음'을 추적하는 컬럼이 스키마에 없으므로, 멘토가 답해야 하는 'pending>0'을
///   주의 표시(attention)로 쓴다 — 가짜 안읽음 수를 만들지 않는다.
class ThreadStatusCounts {
  const ThreadStatusCounts({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.confirmed,
  });

  /// 스레드 총 개수.
  final int total;

  /// 답변 대기(pending) — 멘토가 답할 차례.
  final int pending;

  /// 진행 중(answered/open) — 답변은 갔고 학생 확인 대기.
  final int inProgress;

  /// 답변 완료(confirmed).
  final int confirmed;

  factory ThreadStatusCounts.from(Iterable<QuestionThread> threads) {
    int p = 0, ip = 0, c = 0, t = 0;
    for (final QuestionThread th in threads) {
      t++;
      switch (th.status) {
        case ThreadStatus.pending:
          p++;
          break;
        case ThreadStatus.answered:
        case ThreadStatus.open:
          ip++;
          break;
        case ThreadStatus.confirmed:
          c++;
          break;
        case ThreadStatus.closed:
        case ThreadStatus.archived:
        case ThreadStatus.unknown:
          break; // 내부 취급 — 요약 카운트에서 제외
      }
    }
    return ThreadStatusCounts(total: t, pending: p, inProgress: ip, confirmed: c);
  }

  /// 멘토 주의 필요(답할 게 있음).
  bool get needsAttention => pending > 0;

  /// 목록 행의 상태 요약 한 줄.
  /// 질문 없음 / "답변 대기 N · 진행 중 N" / "모두 답변 완료".
  String get summaryLine {
    if (total == 0) return '질문 없음';
    final List<String> parts = <String>[
      if (pending > 0) '답변 대기 $pending',
      if (inProgress > 0) '진행 중 $inProgress',
    ];
    if (parts.isEmpty) return '모두 답변 완료';
    return parts.join(' · ');
  }
}
