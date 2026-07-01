import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/community/community_screen.dart';
import 'package:ssambership_app/features/community/data/community_models.dart';

import 'fakes.dart';

/// 커뮤니티 탭 셸 — 숏폼/게시판/내활동 탭 + 각 탭 카드 렌더(mock 주입, DB 미접촉).
Widget _wrap(Widget child) => MaterialApp(home: child);

void _bigSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('상단 탭(숏폼/게시판/내 활동)이 존재하고, 숏폼 카드가 렌더된다',
      (WidgetTester tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(_wrap(CommunityScreen(
      read: FakeCommunityRead(shortformsList: <ShortformPost>[sampleShortform()]),
      write: FakeCommunityWrite(),
    )));
    await tester.pumpAndSettle();

    // 탭 3종
    expect(find.text('숏폼'), findsOneWidget);
    expect(find.text('게시판'), findsOneWidget);
    expect(find.text('내 활동'), findsOneWidget);

    // 숏폼 카드(제목·좋아요·조회수)
    expect(find.text('숏폼 제목'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // 좋아요
    expect(find.text('69'), findsOneWidget); // 조회수
  });

  testWidgets('게시판 탭 → 카테고리칩 + 글 카드(제목·댓글수)',
      (WidgetTester tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(_wrap(CommunityScreen(
      read: FakeCommunityRead(boardsList: <BoardPost>[sampleBoard()]),
      write: FakeCommunityWrite(),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('게시판'));
    await tester.pumpAndSettle();

    // 카테고리칩
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('학습'), findsWidgets); // 칩 + 카드 배지
    // 글 카드
    expect(find.text('게시판 제목'), findsOneWidget);
    expect(find.text('7'), findsOneWidget); // 댓글수
  });

  testWidgets('작성 FAB → "작성은 웹에서" 안내(앱 작성화면 없음)',
      (WidgetTester tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(_wrap(CommunityScreen(
      read: const FakeCommunityRead(),
      write: FakeCommunityWrite(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('작성'), findsOneWidget); // FAB
    await tester.tap(find.text('작성'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // 숏폼 탭(기본)에서 → 숏폼 작성 안내
    expect(find.textContaining('작성은 웹에서'), findsOneWidget);
  });
}
