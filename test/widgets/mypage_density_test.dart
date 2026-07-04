import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mypage/data/mypage_models.dart';
import 'package:ssambership_app/features/mypage/ui/sections/mentor_dashboard_section.dart';
import 'package:ssambership_app/features/mypage/ui/sections/student_subscription_section.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('멘토 대시보드: 지표 숫자(3·2) + 최근 정산 한 줄(라벨+금액)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(MentorDashboardSection(
      data: const MentorDashboard(
        studentCount: 3,
        pendingAnswers: 2,
        latestSettlementCents: 4675000,
      ),
      onGoToQuestions: () {},
    )));
    // 구독 학생·답변 대기 → 큰 숫자 메트릭(색 원 아님)
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // 최근 정산 → 라벨 + 금액 한 줄(값은 기존 그대로).
    expect(find.text('최근 정산'), findsOneWidget);
    expect(find.text('46,750원'), findsOneWidget);
  });

  testWidgets('구독 헤더: 활성 구독만 카운트한 배지(2)', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(StudentSubscriptionSection(
      subscriptions: const <SubscriptionCardInfo>[
        SubscriptionCardInfo(mentorName: 'A', isActive: true),
        SubscriptionCardInfo(mentorName: 'B', isActive: true),
        SubscriptionCardInfo(mentorName: 'C', isActive: false),
      ],
      onGoToQuestions: () {},
    )));
    expect(find.text('이용중'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // 활성 2건
  });
}
