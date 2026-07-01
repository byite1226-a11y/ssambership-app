/// 알림 도메인 모델 + 유형 분류.
///
/// ★ 앱 범위: 질문방 · 구독/결제 알림만 노출한다.
///   맞춤의뢰(CR)·환불·개별질문(IQ)은 앱 출시 제외 → [NotificationKind.other] 로 분류해 숨긴다.
///   type 원문(영문 코드)은 화면에 노출하지 않고, 한글 유형 라벨/본문만 쓴다.
library;

/// 알림 유형(앱 범위). other = 앱에서 표시하지 않음(CR·환불·IQ·미지).
enum NotificationKind { questionRoom, subscription, other }

/// 유형 한글 라벨(코드 비노출).
String notificationKindLabel(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.questionRoom:
      return '질문방';
    case NotificationKind.subscription:
      return '구독·결제';
    case NotificationKind.other:
      return '기타';
  }
}

/// notifications.type(자유 텍스트) → 앱 범위 유형.
///
/// 실제 type 어휘는 RLS로 anon 조회가 막혀 확정 열람 불가 → 키워드로 방어적 분류한다.
/// 제외 대상(CR·환불·IQ)을 먼저 걸러 other 로 보낸 뒤, 구독/질문방을 판별한다.
NotificationKind classifyNotificationType(String? type) {
  final String t = (type ?? '').toLowerCase();

  // 앱 범위 밖(반드시 먼저): 맞춤의뢰(CR)·환불·개별질문(IQ).
  if (t.contains('custom_request') ||
      t.contains('custom_order') ||
      t.contains('refund') ||
      t.contains('individual_question') ||
      t.startsWith('cr_') ||
      t.startsWith('iq_')) {
    return NotificationKind.other;
  }

  // 구독·결제.
  if (t.contains('subscription') ||
      t.contains('billing') ||
      t.contains('payment') ||
      t.contains('renew')) {
    return NotificationKind.subscription;
  }

  // 질문방(스레드·메시지·답변·연결노트).
  if (t.contains('question') ||
      t.contains('thread') ||
      t.contains('answer') ||
      t.contains('message') ||
      t.contains('room') ||
      t.contains('note')) {
    return NotificationKind.questionRoom;
  }

  return NotificationKind.other;
}

/// 본문이 비어 있을 때의 유형별 폴백(날조 아님 — 유형 안내만).
String _fallbackBody(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.questionRoom:
      return '질문방에 새 소식이 있어요.';
    case NotificationKind.subscription:
      return '구독·결제 관련 알림이에요.';
    case NotificationKind.other:
      return '새 알림이 있어요.';
  }
}

/// 알림 1건(조회·읽음 대상). 내부 id·type 원문은 화면에 노출하지 않는다.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final NotificationKind kind;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// 앱에서 노출할 범위인지(질문방·구독만).
  bool get inAppScope => kind != NotificationKind.other;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        kind: kind,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final NotificationKind kind = classifyNotificationType(map['type'] as String?);
    final String rawBody = (map['body'] as String?)?.trim() ?? '';
    final bool read = (map['is_read'] as bool?) ?? (map['read'] as bool?) ?? false;
    return AppNotification(
      id: map['id'] as String,
      kind: kind,
      body: rawBody.isEmpty ? _fallbackBody(kind) : rawBody,
      isRead: read,
      createdAt: _parseTime(map['created_at']),
    );
  }
}

DateTime _parseTime(Object? v) {
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
