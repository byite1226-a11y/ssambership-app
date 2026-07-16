import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/community/ui/board/board_write_screen.dart';
import 'package:ssambership_app/features/community/ui/widgets/content_policy_gate.dart';

import 'fakes.dart';

/// 게시판 글쓰기 스모크 — DB 미접촉(FakeCommunityWrite 주입).
void main() {
  testWidgets('필수값 검증: 제목·내용 비면 제출 차단 + 안내', (WidgetTester tester) async {
    final FakeCommunityWrite fake = FakeCommunityWrite();
    await tester.pumpWidget(MaterialApp(home: BoardWriteScreen(write: fake)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('등록'));
    await tester.pump();

    expect(find.text('제목과 내용을 입력해 주세요.'), findsOneWidget);
    expect(fake.postCalls, 0);
  });

  testWidgets('제출 성공: 정책 동의 게이트 통과 → createPost 호출 + pop(true)',
      (WidgetTester tester) async {
    // P0-3(UGC): 첫 게시 전 커뮤니티 이용 규정 동의 다이얼로그가 뜬다.
    // 게이트 자체의 상세 동작은 content_policy_gate_test 에서 검증.
    ContentPolicyGate.agreedThisSession = false;
    final FakeCommunityWrite fake = FakeCommunityWrite();
    bool? popResult;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext ctx) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                popResult = await Navigator.of(ctx).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => BoardWriteScreen(write: fake),
                  ),
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    // TextField 는 제목·내용 순(카테고리는 드롭다운).
    await tester.enterText(find.byType(TextField).at(0), '오답노트 공유');
    await tester.enterText(find.byType(TextField).at(1), '이렇게 정리했어요.');
    await tester.tap(find.text('등록'));
    await tester.pumpAndSettle();

    // 게시 전 정책 동의 게이트(최초 1회) → 동의하고 계속.
    expect(find.text('커뮤니티 이용 규정'), findsOneWidget);
    expect(fake.postCalls, 0); // 동의 전엔 게시되지 않는다.
    await tester.tap(find.text('동의하고 계속'));
    await tester.pumpAndSettle();

    expect(fake.postCalls, 1);
    expect(fake.lastPostTitle, '오답노트 공유');
    expect(fake.lastPostBody, '이렇게 정리했어요.');
    expect(fake.lastPostCategory, 'study'); // 기본 선택 = 첫 옵션(학습법)
    expect(popResult, isTrue);
  });
}
