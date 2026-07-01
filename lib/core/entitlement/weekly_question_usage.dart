/// 주간 질문 사용량(읽기 전용). DB RPC `get_weekly_question_usage(p_student_id, p_mentor_id)`
/// 반환 JSON을 그대로 담는다.
///
/// ★ tier별 한도(limited=4/standard=9/premium=999)는 **DB(RPC)가 정본**이다.
///   앱은 이 반환값(used/limit/remaining/can_ask)만 쓰고 한도 숫자를 재하드코딩하지 않는다.
///
/// A2(질문 주간한도)의 앱-계층 검사에 쓰인다. 단, 이 검사는 '클라이언트 검사'라
/// 앱을 우회한 직접 INSERT는 못 막는다. 서버측 강제는 DB 트리거가 필요하다(출시 후 보강).
class WeeklyQuestionUsage {
  const WeeklyQuestionUsage({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.canAsk,
    this.planTier,
    this.weekStart,
    this.weekEnd,
  });

  final int used;
  final int limit;
  final int remaining;
  final bool canAsk;
  final String? planTier;
  final DateTime? weekStart;
  final DateTime? weekEnd;

  /// 사실상 무제한(프리미엄 FUP 등) 여부 — 큰 잔여수를 숫자로 노출하지 않기 위한 표시 기준.
  /// (한도 숫자를 재정의하는 게 아니라, RPC가 준 limit 이 매우 크면 '충분'으로 표시.)
  bool get isEffectivelyUnlimited => limit >= 999;

  /// 구독/한도 정보가 유효한지(표시할 값이 있는지).
  bool get hasQuota => limit > 0;

  /// 질문방·작성 화면에 띄울 잔여 안내. 값이 없으면 null(표시 생략).
  String? get remainingLabel {
    if (!hasQuota) return null;
    if (isEffectivelyUnlimited) return '이번 주 질문 가능';
    return '이번 주 남은 질문 $remaining개';
  }

  /// 한도 초과 차단 시 담백한 안내 문구.
  String get blockMessage {
    final String count = hasQuota ? ' (사용 $used/$limit)' : '';
    return '이번 주 질문 가능 횟수를 모두 사용했어요.$count 다음 주기에 다시 질문할 수 있어요.';
  }

  /// RPC 반환(JSON object) → 모델. 예상치 못한 형태면 null.
  static WeeklyQuestionUsage? fromRpc(Object? data) {
    if (data is! Map) return null;
    final Map<Object?, Object?> m = data;
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    final int used = asInt(m['used']);
    final int limit = asInt(m['limit']);
    final int remaining =
        m['remaining'] != null ? asInt(m['remaining']) : (limit - used);
    final Object? canAskRaw = m['can_ask'];
    final bool canAsk =
        canAskRaw is bool ? canAskRaw : (used < limit); // 폴백: 사용<한도

    final String tier = m['plan_tier']?.toString().trim() ?? '';

    return WeeklyQuestionUsage(
      used: used,
      limit: limit,
      remaining: remaining < 0 ? 0 : remaining,
      canAsk: canAsk,
      planTier: tier.isEmpty ? null : tier,
      weekStart: _time(m['week_start']),
      weekEnd: _time(m['week_end']),
    );
  }

  static DateTime? _time(Object? v) {
    if (v is String && v.trim().isNotEmpty) {
      return DateTime.tryParse(v.trim())?.toLocal();
    }
    return null;
  }
}
