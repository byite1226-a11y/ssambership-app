import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mypage/ui/sections/settings_section.dart';

/// 설정 섹션 — 로그아웃 버튼 존재·동작 연결(콜백 주입), 알림 토글·앱 버전.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('로그아웃 버튼이 존재하고 탭하면 onLogout 콜백이 호출된다',
      (WidgetTester tester) async {
    int logouts = 0;
    await tester.pumpWidget(_wrap(
      SettingsSection(onLogout: () => logouts++),
    ));

    expect(find.text('로그아웃'), findsOneWidget);
    await tester.tap(find.text('로그아웃'));
    await tester.pump();
    expect(logouts, 1);
  });

  testWidgets('알림 토글(Switch)·약관·앱 버전이 렌더된다', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      SettingsSection(onLogout: () {}),
    ));
    expect(find.text('알림 받기'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('개인정보 처리방침'), findsOneWidget);
    expect(find.text('앱 버전'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget); // AppConstants.appVersion
  });

  testWidgets('showLogout=false(게스트)면 로그아웃 버튼 비표시',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      SettingsSection(onLogout: () {}, showLogout: false),
    ));
    expect(find.text('로그아웃'), findsNothing);
  });
}
