import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/community/data/user_blocks_repository.dart';
import 'package:ssambership_app/features/community/ui/blocks/blocked_users_screen.dart';

/// 차단 목록 화면 — DB 미접촉(레포 서브클래스로 주입).
class _FakeBlocks extends UserBlocksRepository {
  _FakeBlocks(this._users);
  List<BlockedUser> _users;
  final List<String> unblocked = <String>[];

  @override
  Future<List<BlockedUser>> myBlockedUsers() async => _users;

  @override
  Future<bool> unblock(String blockedId) async {
    unblocked.add(blockedId);
    _users =
        _users.where((BlockedUser u) => u.userId != blockedId).toList();
    return true;
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('차단 목록 렌더 + 해제 시 목록에서 사라짐', (WidgetTester tester) async {
    final _FakeBlocks fake = _FakeBlocks(<BlockedUser>[
      const BlockedUser(userId: 'u1', displayName: '홍길동'),
      const BlockedUser(userId: 'u2', displayName: '김철수'),
    ]);
    await tester.pumpWidget(_wrap(BlockedUsersScreen(repository: fake)));
    await tester.pumpAndSettle();

    expect(find.text('홍길동'), findsOneWidget);
    expect(find.text('김철수'), findsOneWidget);
    expect(find.text('차단 해제'), findsNWidgets(2));

    await tester.tap(find.text('차단 해제').first);
    await tester.pumpAndSettle();

    expect(fake.unblocked, contains('u1'));
    expect(find.text('홍길동'), findsNothing);
    expect(find.text('김철수'), findsOneWidget);
  });

  testWidgets('차단 없음 → EmptyState', (WidgetTester tester) async {
    await tester.pumpWidget(
        _wrap(BlockedUsersScreen(repository: _FakeBlocks(<BlockedUser>[]))));
    await tester.pumpAndSettle();
    expect(find.text('차단한 사용자가 없어요'), findsOneWidget);
  });
}
