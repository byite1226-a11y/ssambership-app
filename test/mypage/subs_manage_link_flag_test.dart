import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/commerce/commerce_policy.dart';
import 'package:ssambership_app/features/mypage/data/mypage_models.dart';
import 'package:ssambership_app/features/mypage/ui/sections/student_subscription_section.dart';

/// '구독 관리 (웹)' 링크 ↔ kSubscriptionManageLinkEnabled 연동 상시 검증.
///
/// ★ P0-3 옵션1(2026-07): 플래그는 컴파일 타임 주입 — 기본 false(스토어 빌드),
///   `flutter test --dart-define=SUBS_MANAGE_LINK_ENABLED=true` 로 on 상태도
///   같은 테스트로 검증(플래그 값 기준 단언 — 어느 모드든 녹색).
/// off 일 때 죽은 버튼·빈 공백 대신 안내 카드가 그려짐(P0-4 재발 방지)도 고정.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  testWidgets('구독 관리 링크는 플래그를 따르고, off 면 안내 카드로 대체된다',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(StudentSubscriptionSection(
      subscriptions: <SubscriptionCardInfo>[
        SubscriptionCardInfo(
          mentorName: '김멘토',
          isActive: true,
          nextRenewal: DateTime(2026, 7, 27),
        ),
      ],
      onGoToQuestions: () {},
    )));
    await tester.pumpAndSettle();

    if (kSubscriptionManageLinkEnabled) {
      expect(find.text('구독 관리 (웹)'), findsOneWidget);
      expect(find.text(kSubscriptionManageNoticeText), findsNothing);
    } else {
      // 스토어 빌드(기본): 링크 숨김 + 비상호작용 안내로 대체(빈 공백 금지).
      expect(find.text('구독 관리 (웹)'), findsNothing);
      expect(find.text(kSubscriptionManageNoticeText), findsOneWidget);
    }
    // 구독 상태 조회 표시는 플래그와 무관하게 유지된다.
    expect(find.text('김멘토'), findsOneWidget);
  });
}
