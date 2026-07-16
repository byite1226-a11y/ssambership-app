import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/community/data/community_models.dart';
import 'package:ssambership_app/features/community/ui/widgets/comment_tile.dart';
import 'package:ssambership_app/features/community/ui/widgets/content_policy_gate.dart';

/// UGC 심사 요건 검증(P0-3):
///  - 게시 전 커뮤니티 이용 규정 '동의' 게이트가 최초 1회 노출·저장된다.
///  - 댓글 항목의 ⋯ 메뉴에 '신고' 동선이 노출된다.
void main() {
  setUp(() => ContentPolicyGate.agreedThisSession = false);

  Widget _host(Future<void> Function(BuildContext) onTap) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext c) => TextButton(
              onPressed: () => onTap(c),
              child: const Text('go'),
            ),
          ),
        ),
      );

  testWidgets('최초 게시: 규정 다이얼로그 노출 → 동의 시 true + 세션 저장',
      (WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(_host((BuildContext c) async {
      result = await ContentPolicyGate.ensureAgreed(c);
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // 규정 다이얼로그가 떠 있다.
    expect(find.text('커뮤니티 이용 규정'), findsOneWidget);
    // 동의.
    await tester.tap(find.text('동의하고 계속'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(ContentPolicyGate.agreedThisSession, isTrue);
  });

  testWidgets('동의 후 재게시: 다이얼로그 없이 즉시 true',
      (WidgetTester tester) async {
    ContentPolicyGate.agreedThisSession = true;
    bool? result;
    await tester.pumpWidget(_host((BuildContext c) async {
      result = await ContentPolicyGate.ensureAgreed(c);
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('커뮤니티 이용 규정'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('취소: false 반환 + 미동의 유지', (WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(_host((BuildContext c) async {
      result = await ContentPolicyGate.ensureAgreed(c);
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(ContentPolicyGate.agreedThisSession, isFalse);
  });

  testWidgets('댓글 ⋯ 메뉴: onReport 지정 시 "신고" 노출',
      (WidgetTester tester) async {
    bool reported = false;
    final CommunityComment c = CommunityComment(
      id: 'c1',
      body: '댓글 본문',
      createdAt: DateTime(2026, 7, 14),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommentTile(
          comment: c,
          onReport: () => reported = true,
          onBlock: () {},
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('신고'), findsOneWidget);
    expect(find.text('이 사용자 차단'), findsOneWidget);
    await tester.tap(find.text('신고'));
    await tester.pumpAndSettle();
    expect(reported, isTrue);
  });
}
