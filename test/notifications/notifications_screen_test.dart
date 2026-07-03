import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/design/widgets/chip_scroll.dart';
import 'package:ssambership_app/design/widgets/count_badge.dart';
import 'package:ssambership_app/features/notifications/data/app_notification.dart';
import 'package:ssambership_app/features/notifications/data/notifications_repository.dart';
import 'package:ssambership_app/features/notifications/notifications_screen.dart';
import 'package:ssambership_app/features/notifications/ui/widgets/notification_card.dart';

/// 필터링을 화면이 하는지 보기 위해, fake 는 원본(제외 대상 포함)을 그대로 돌려준다.
class _FakeRepo implements NotificationsRepository {
  _FakeRepo(this.items);
  final List<AppNotification> items;
  final List<String> readCalls = <String>[];
  bool allReadCalled = false;

  @override
  Future<NotificationsPage> fetch({int limit = 20, int offset = 0}) async {
    final List<AppNotification> page = items.skip(offset).take(limit).toList();
    return NotificationsPage(items: page, hasMore: false);
  }

  @override
  Future<void> markRead(String id) async => readCalls.add(id);

  @override
  Future<void> markAllRead(List<String> ids) async {
    allReadCalled = true;
    readCalls.addAll(ids);
  }
}

AppNotification _n(
  String id,
  NotificationKind kind,
  String body, {
  bool read = false,
  int minute = 0,
}) =>
    AppNotification(
      id: id,
      kind: kind,
      body: body,
      isRead: read,
      createdAt: DateTime(2026, 7, 1, 10, minute),
    );

List<AppNotification> _sample() => <AppNotification>[
      _n('a', NotificationKind.questionRoom, 'A 질문방 알림', minute: 5),
      _n('b', NotificationKind.subscription, 'B 구독 알림', minute: 4),
      _n('c', NotificationKind.questionRoom, 'C 읽은 질문방', read: true, minute: 3),
      _n('d', NotificationKind.other, 'D 의뢰(CR) 알림', minute: 2),
      _n('e', NotificationKind.other, 'E 환불 알림', minute: 1),
    ];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Finder _typeChip(String label) =>
    find.descendant(of: find.byType(ChipScroll), matching: find.text(label));

Finder _readBtnOf(String body) => find.descendant(
      of: find.ancestor(
          of: find.text(body), matching: find.byType(NotificationCard)),
      matching: find.text('읽음'),
    );

void main() {
  testWidgets('앱 범위(질문방·구독)만 렌더 + CR/환불 제외 + 안읽음 카운트',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(NotificationsScreen(
      repository: _FakeRepo(_sample()),
      onDeepLinkTab: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('A 질문방 알림'), findsOneWidget);
    expect(find.text('B 구독 알림'), findsOneWidget);
    expect(find.text('C 읽은 질문방'), findsOneWidget);
    // CR·환불은 노출되지 않는다.
    expect(find.text('D 의뢰(CR) 알림'), findsNothing);
    expect(find.text('E 환불 알림'), findsNothing);
    // 안읽음 = A,B (C는 읽음, D·E 제외).
    expect(find.text('안 읽음'), findsOneWidget);
    expect(tester.widget<CountBadge>(find.byType(CountBadge)).count, 2);
  });

  testWidgets('읽지 않음 토글 → 읽은 알림 숨김', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(NotificationsScreen(
      repository: _FakeRepo(_sample()),
      onDeepLinkTab: (_) {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('읽지 않음'));
    await tester.pumpAndSettle();

    expect(find.text('A 질문방 알림'), findsOneWidget);
    expect(find.text('B 구독 알림'), findsOneWidget);
    expect(find.text('C 읽은 질문방'), findsNothing); // 읽음 → 숨김
  });

  testWidgets('유형 필터(질문방) → 구독 알림 숨김', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(NotificationsScreen(
      repository: _FakeRepo(_sample()),
      onDeepLinkTab: (_) {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(_typeChip('질문방'));
    await tester.pumpAndSettle();

    expect(find.text('A 질문방 알림'), findsOneWidget);
    expect(find.text('C 읽은 질문방'), findsOneWidget);
    expect(find.text('B 구독 알림'), findsNothing); // 구독은 숨김
  });

  testWidgets('읽음 처리 → repo.markRead 호출 + 안읽음 카운트 감소',
      (WidgetTester tester) async {
    final _FakeRepo repo = _FakeRepo(_sample());
    await tester.pumpWidget(_wrap(NotificationsScreen(
      repository: repo,
      onDeepLinkTab: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('안 읽음'), findsOneWidget);
    expect(tester.widget<CountBadge>(find.byType(CountBadge)).count, 2);
    await tester.tap(_readBtnOf('A 질문방 알림'));
    await tester.pumpAndSettle();

    expect(repo.readCalls, contains('a'));
    expect(tester.widget<CountBadge>(find.byType(CountBadge)).count, 1);
  });

  testWidgets('모두 읽음 → 전부 읽음 처리 + 카운트 0', (WidgetTester tester) async {
    final _FakeRepo repo = _FakeRepo(_sample());
    await tester.pumpWidget(_wrap(NotificationsScreen(
      repository: repo,
      onDeepLinkTab: (_) {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('모두 읽음'));
    await tester.pumpAndSettle();

    expect(repo.allReadCalled, true);
    expect(find.text('안 읽음'), findsOneWidget);
    expect(tester.widget<CountBadge>(find.byType(CountBadge)).count, 0);
  });

  testWidgets('딥링크: 질문방 알림 → 질문방 탭(0), 구독 알림 → 마이페이지 탭(4)',
      (WidgetTester tester) async {
    final List<int> tabs = <int>[];
    await tester.pumpWidget(_wrap(NotificationsScreen(
      repository: _FakeRepo(_sample()),
      onDeepLinkTab: tabs.add,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A 질문방 알림'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B 구독 알림'));
    await tester.pumpAndSettle();

    expect(tabs, <int>[0, 4]);
  });

  testWidgets('빈 상태 안내', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(NotificationsScreen(
      repository: _FakeRepo(<AppNotification>[]),
      onDeepLinkTab: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('새 알림이 없어요'), findsOneWidget);
  });
}
