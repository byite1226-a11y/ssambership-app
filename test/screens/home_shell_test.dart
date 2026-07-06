import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ssambership_app/app/app_tabs.dart';
import 'package:ssambership_app/app/home_shell.dart';
import 'package:ssambership_app/core/auth/auth_service.dart';
import 'package:ssambership_app/shared/constants/app_constants.dart';

/// HomeShell(하단 5탭 셸) — 탭 구성·게스트 가드·프로필 push·딥링크 가상 목적지.
/// Supabase 미초기화 상태에서 각 탭 화면은 에러/빈 상태로 그려진다(DB 비접촉).
///
/// 주의: AuthService 는 싱글턴이라 게스트 상태를 쓰는 테스트는 tearDown 에서
/// signOut() 으로 원복한다(클라이언트 없음 → 세션 호출 없이 상태만 리셋).
void main() {
  Widget app() => MaterialApp.router(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: <RouteBase>[
            GoRoute(path: '/', builder: (_, __) => const HomeShell()),
            GoRoute(
              path: '/login',
              builder: (_, GoRouterState state) => Scaffold(
                body: Text(
                    'LOGIN:${state.uri.queryParameters['notice'] ?? ''}'),
              ),
            ),
          ],
        ),
      );

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(app());
    // 각 탭 화면의 FutureBuilder 가 (클라이언트 없음) 에러/빈 상태로 정착할 때까지.
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    // 게스트 상태 원복(싱글턴 오염 방지). 클라이언트 없음 → 상태 리셋만 수행.
    await AuthService.instance.signOut();
    TabNavigator.request.value = -1;
  });

  testWidgets('하단 탭 5개: 질문방·커뮤니티·멘토 찾기·알림·개별질문 (마이페이지 탭 없음)',
      (WidgetTester tester) async {
    await pumpShell(tester);

    final NavigationBar bar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 5);
    for (final String label in AppConstants.bottomTabLabels) {
      expect(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(AppConstants.bottomTabLabels, isNot(contains('마이페이지')));
    expect(AppConstants.bottomTabLabels[AppTab.individualQuestion], '개별질문');
  });

  testWidgets('우측 상단 프로필 버튼 → 마이페이지 push (탭 전환 아님)',
      (WidgetTester tester) async {
    await pumpShell(tester);

    await tester.tap(find.bySemanticsLabel(AppConstants.myPageTitle));
    await tester.pumpAndSettle();

    // push 된 화면의 AppBar 타이틀.
    expect(find.text(AppConstants.myPageTitle), findsOneWidget);
    // 하단 탭 셸은 뒤에 그대로(뒤로가기로 복귀 가능).
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('게스트: 질문방·알림·개별질문 탭 → 로그인 안내 리다이렉트',
      (WidgetTester tester) async {
    AuthService.instance.enterAsGuest();
    await pumpShell(tester);

    // 커뮤니티(허용 탭)로 먼저 이동해 두고, 보호 탭을 눌러본다.
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('커뮤니티')));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('개별질문')));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN:login_required'), findsOneWidget);
  });

  testWidgets('게스트: 커뮤니티·멘토 찾기 탭은 허용(리다이렉트 없음)',
      (WidgetTester tester) async {
    AuthService.instance.enterAsGuest();
    await pumpShell(tester);

    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('멘토 찾기')));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN:login_required'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('게스트: 프로필 버튼 → 로그인 안내 리다이렉트',
      (WidgetTester tester) async {
    AuthService.instance.enterAsGuest();
    await pumpShell(tester);

    await tester.tap(find.bySemanticsLabel(AppConstants.myPageTitle));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN:login_required'), findsOneWidget);
  });

  testWidgets('딥링크: AppTab.myPage(=100) 는 탭 전환이 아니라 마이페이지 push',
      (WidgetTester tester) async {
    await pumpShell(tester);

    TabNavigator.go(AppTab.myPage);
    await tester.pumpAndSettle();

    // push 된 마이페이지가 보이고, 처리 후 요청 채널은 -1 로 리셋된다.
    expect(find.text(AppConstants.myPageTitle), findsOneWidget);
    expect(TabNavigator.request.value, -1);

    // 뒤로 가면 셸의 탭 인덱스는 변하지 않았다(질문방 유지).
    await tester.pageBack();
    await tester.pumpAndSettle();
    final NavigationBar bar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.questionRoom);
  });

  testWidgets('딥링크: 개별질문(4) 탭 전환 + -1 리셋 + 같은 탭 재요청도 처리',
      (WidgetTester tester) async {
    await pumpShell(tester);

    TabNavigator.go(AppTab.individualQuestion);
    await tester.pumpAndSettle();
    NavigationBar bar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.individualQuestion);
    expect(TabNavigator.request.value, -1); // 처리 후 리셋 → 재요청 감지 가능.

    // 다른 탭으로 갔다가 같은 값(4)을 다시 요청해도 처리된다.
    TabNavigator.go(AppTab.community);
    await tester.pumpAndSettle();
    TabNavigator.go(AppTab.individualQuestion);
    await tester.pumpAndSettle();
    bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.individualQuestion);
    expect(TabNavigator.request.value, -1);
  });

  testWidgets('작은 뷰포트(320×568): 셸 + 전 탭 전환에 오버플로 예외 없음',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpShell(tester);
    expect(tester.takeException(), isNull);

    for (final String label in AppConstants.bottomTabLabels) {
      await tester.tap(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text(label)),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label 탭 오버플로/예외');
    }
  });
}
