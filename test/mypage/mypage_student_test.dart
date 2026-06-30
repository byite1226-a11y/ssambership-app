import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/auth/auth_service.dart' show AppRole;
import 'package:ssambership_app/features/mypage/data/mypage_models.dart';
import 'package:ssambership_app/features/mypage/mypage_screen.dart';

/// 학생 마이페이지 — mock MyPageData 주입(실제 DB·네트워크 미사용)으로 섹션 렌더 검증.
MyPageData _studentData() => MyPageData(
      role: AppRole.student,
      profile: const MyProfile(
        name: '로컬학생',
        roleLabel: '학생',
        email: 'local.student@ssam.test',
        grade: '고2',
      ),
      subscriptions: <SubscriptionCardInfo>[
        SubscriptionCardInfo(
          mentorName: '김멘토',
          isActive: true,
          planTier: 'standard', // 요금제명 미확정 → 카드에 라벨 안 뜸
          nextRenewal: DateTime(2026, 7, 27),
          remaining: null, // ★ 미확정 → 숫자 대신 상태 표기
        ),
        const SubscriptionCardInfo(mentorName: '박멘토', isActive: false),
      ],
      cash: CashSummary(
        balanceCents: 5000000, // 50,000원
        recent: <CashEntry>[
          CashEntry(deltaCents: 5000000, createdAt: DateTime(2026, 6, 27)),
          CashEntry(deltaCents: -120000, createdAt: DateTime(2026, 6, 28)),
        ],
      ),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// ListView 가 지연 빌드되지 않도록 충분히 큰 화면으로.
void _bigSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('프로필·구독현황·캐시·설정 섹션이 렌더된다',
      (WidgetTester tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(
        _wrap(MyPageScreen(loaderOverride: () async => _studentData())));
    await tester.pump(); // FutureBuilder 해소

    expect(find.text('로컬학생'), findsOneWidget);
    expect(find.text('local.student@ssam.test'), findsOneWidget);
    expect(find.text('구독 현황'), findsOneWidget);
    expect(find.text('캐시'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('질문하러 가기'), findsOneWidget);
  });

  testWidgets('구독 카드가 멘토별로 렌더(상태칩·갱신일), 잔여수 미확정은 숫자 날조 없이 상태 표기',
      (WidgetTester tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(
        _wrap(MyPageScreen(loaderOverride: () async => _studentData())));
    await tester.pump();

    expect(find.text('김멘토'), findsOneWidget);
    expect(find.text('박멘토'), findsOneWidget);
    expect(find.text('구독 중'), findsOneWidget);
    expect(find.text('구독 만료'), findsOneWidget);
    expect(find.textContaining('다음 갱신 7/27'), findsOneWidget);
    // remaining null → "남은 질문 N개" 같은 날조 숫자 없이 상태 문구.
    expect(find.textContaining('구독 상태로 질문 가능'), findsOneWidget);
    expect(find.textContaining('남은 질문'), findsNothing);
  });

  testWidgets('캐시 잔액 조회 표기 + "충전하기/결제 관리"는 웹 브릿지(앱 결제화면 없음)',
      (WidgetTester tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(
        _wrap(MyPageScreen(loaderOverride: () async => _studentData())));
    await tester.pump();

    expect(find.text('보유 캐시'), findsOneWidget);
    expect(find.text('50,000원'), findsOneWidget); // 조회 표기
    expect(find.text('충전하기 (웹)'), findsOneWidget);
    expect(find.text('결제·구독 관리 (웹)'), findsOneWidget);

    // 충전하기 탭 → 웹 안내 스낵바(앱에서 결제 실행 없음).
    await tester.tap(find.text('충전하기 (웹)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('충전은 웹에서'), findsOneWidget);
  });
}

// 참고: AuthService 싱글톤은 테스트에서 세션이 없어 isSignedIn=false → 로그아웃 버튼 비표시.
//       로그아웃 동작은 settings_section_test 에서 별도 검증(콜백 주입).
