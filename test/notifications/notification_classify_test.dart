import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/notifications/data/app_notification.dart';

void main() {
  test('질문방 유형으로 분류', () {
    for (final String t in <String>[
      'question_answered',
      'thread_message',
      'new_answer',
      'connection_note_added',
      'question_room_message',
    ]) {
      expect(classifyNotificationType(t), NotificationKind.questionRoom,
          reason: t);
    }
  });

  test('구독·결제 유형으로 분류', () {
    for (final String t in <String>[
      'subscription_renewed',
      'payment_succeeded',
      'billing_reminder',
      'subscription_expiring',
    ]) {
      expect(classifyNotificationType(t), NotificationKind.subscription,
          reason: t);
    }
  });

  test('CR·환불·IQ 는 other(앱 범위 밖) — subscription_refund 도 환불 우선', () {
    for (final String t in <String>[
      'custom_request_new',
      'custom_order_delivered',
      'refund_approved',
      'individual_question_answered',
      'subscription_refund', // refund 우선 → other
    ]) {
      expect(classifyNotificationType(t), NotificationKind.other, reason: t);
    }
  });

  test('미지·빈 유형 → other', () {
    expect(classifyNotificationType(null), NotificationKind.other);
    expect(classifyNotificationType(''), NotificationKind.other);
    expect(classifyNotificationType('weird_unknown'), NotificationKind.other);
  });

  test('fromMap: 유형/본문/읽음 파싱 + inAppScope', () {
    final AppNotification n = AppNotification.fromMap(<String, dynamic>{
      'id': '1',
      'type': 'question_answered',
      'body': '답변이 도착했어요',
      'is_read': false,
      'created_at': '2026-07-01T00:00:00Z',
    });
    expect(n.kind, NotificationKind.questionRoom);
    expect(n.inAppScope, true);
    expect(n.body, '답변이 도착했어요');
    expect(n.isRead, false);

    final AppNotification cr = AppNotification.fromMap(<String, dynamic>{
      'id': '2',
      'type': 'refund_approved',
      'body': '환불 처리',
      'is_read': false,
      'created_at': '2026-07-01T00:00:00Z',
    });
    expect(cr.inAppScope, false);
  });

  test('본문 비면 유형별 폴백(날조 아님)', () {
    final AppNotification n = AppNotification.fromMap(<String, dynamic>{
      'id': '3',
      'type': 'subscription_renewed',
      'body': '',
      'is_read': true,
      'created_at': '2026-07-01T00:00:00Z',
    });
    expect(n.body.isNotEmpty, true);
    expect(n.isRead, true);
  });
}
