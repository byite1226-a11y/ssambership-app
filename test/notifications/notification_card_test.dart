import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/notifications/data/app_notification.dart';
import 'package:ssambership_app/features/notifications/ui/widgets/notification_card.dart';

AppNotification _n({
  bool read = false,
  NotificationKind kind = NotificationKind.questionRoom,
  String body = '새 답변이 있어요',
}) =>
    AppNotification(
      id: '1',
      kind: kind,
      body: body,
      isRead: read,
      createdAt: DateTime(2026, 7, 1, 10, 0),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('유형칩·본문·읽음 버튼 렌더 + 탭/읽음 콜백',
      (WidgetTester tester) async {
    int open = 0;
    int read = 0;
    await tester.pumpWidget(_wrap(NotificationCard(
      notification: _n(),
      onOpen: () => open++,
      onMarkRead: () => read++,
    )));

    expect(find.text('질문방'), findsOneWidget); // 유형칩(한글, 코드 비노출)
    expect(find.text('새 답변이 있어요'), findsOneWidget);
    expect(find.text('읽음'), findsOneWidget);

    await tester.tap(find.text('읽음'));
    await tester.pump();
    expect(read, 1);
    expect(open, 0); // 읽음 버튼은 이동하지 않음

    await tester.tap(find.text('새 답변이 있어요'));
    await tester.pump();
    expect(open, 1);
  });

  testWidgets('읽은 알림은 "읽음" 버튼이 없다', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(NotificationCard(
      notification: _n(read: true),
      onOpen: () {},
      onMarkRead: () {},
    )));
    expect(find.text('읽음'), findsNothing);
  });
}
