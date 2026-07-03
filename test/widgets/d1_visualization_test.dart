import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/design/widgets/count_badge.dart';
import 'package:ssambership_app/design/widgets/money_display.dart';
import 'package:ssambership_app/design/widgets/quota_bar.dart';
import 'package:ssambership_app/design/widgets/status_pill.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

double _fraction(WidgetTester tester) =>
    tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor!;

void main() {
  group('QuotaBar(D1-A)', () {
    testWidgets('잔여 꽉참(0/4 사용) → 바 100%, 라벨 표기', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const QuotaBar(used: 0, limit: 4)));
      expect(find.text('주 4개 질문'), findsOneWidget);
      expect(find.text('잔여 4/4'), findsOneWidget);
      expect(_fraction(tester), 1.0);
    });

    testWidgets('잔여 없음(4/4 사용) → 바 0%', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const QuotaBar(used: 4, limit: 4)));
      expect(find.text('잔여 0/4'), findsOneWidget);
      expect(_fraction(tester), 0.0);
    });

    testWidgets('절반(2/4 사용) → 바 50%', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const QuotaBar(used: 2, limit: 4)));
      expect(_fraction(tester), 0.5);
    });

    testWidgets('무제한(limit 999) → 바 없이 "주 무제한 질문"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const QuotaBar(used: 3, limit: 999)));
      expect(find.text('주 무제한 질문'), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsNothing);
    });

    testWidgets('한도 정보 없음(limit 0) → 아무것도 안 그림',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const QuotaBar(used: 0, limit: 0)));
      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(find.textContaining('잔여'), findsNothing);
    });
  });

  group('CountBadge(D1-D)', () {
    testWidgets('양수는 숫자 렌더', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CountBadge(count: 3)));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('0이면 숨김', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CountBadge(count: 0)));
      expect(find.text('0'), findsNothing);
    });

    testWidgets('max 초과는 "99+"', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CountBadge(count: 150)));
      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('StatusDot / StatusPill(D1-B)', () {
    testWidgets('showDot=true 면 상태 도트가 붙는다', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(
          const StatusPill(label: '이용 중', tone: StatusTone.success, showDot: true)));
      expect(find.text('이용 중'), findsOneWidget);
      expect(find.byType(StatusDot), findsOneWidget);
    });

    testWidgets('showDot=false 면 도트 없음', (WidgetTester tester) async {
      await tester.pumpWidget(
          _wrap(const StatusPill(label: '만료됨', tone: StatusTone.neutral)));
      expect(find.byType(StatusDot), findsNothing);
    });
  });

  group('MoneyDisplay(D1-C)', () {
    testWidgets('라벨 + 금액 렌더', (WidgetTester tester) async {
      await tester.pumpWidget(
          _wrap(const MoneyDisplay(label: '보유 캐시', amount: '45,000원')));
      expect(find.text('보유 캐시'), findsOneWidget);
      expect(find.text('45,000원'), findsOneWidget);
    });
  });
}
