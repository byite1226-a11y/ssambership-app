import 'package:flutter/material.dart';

import '../../design/role_accent.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/typography_tokens.dart';
import 'data/community_read_repository.dart';
import 'data/community_write_repository.dart';
import 'ui/activity/my_activity_view.dart';
import 'ui/board/board_list_view.dart';
import 'ui/shortform/shortform_feed_view.dart';
import 'ui/widgets/community_write_notice.dart';

/// 커뮤니티 탭. 상단 탭(숏폼 / 게시판 / 내 활동). HomeShell 이 바깥 AppBar/하단탭 제공.
///
/// ★ 앱은 열람 + 반응(좋아요·스크랩·댓글·신고)만. 글·숏폼 '작성'은 웹에서(FAB → 안내).
///   레포는 테스트에서 fake 로 주입할 수 있게 optional 로 받는다(기본은 실제).
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({
    super.key,
    this.read = const CommunityReadRepository(),
    this.write = const CommunityWriteRepository(),
  });

  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            TabBar(
              labelColor: AppAccent.of(context).accent,
              unselectedLabelColor: ColorTokens.secondary,
              indicatorColor: AppAccent.of(context).accent,
              labelStyle: AppType.body,
              tabs: const <Widget>[
                Tab(text: '숏폼'),
                Tab(text: '게시판'),
                Tab(text: '내 활동'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  ShortformFeedView(read: read, write: write),
                  BoardListView(read: read, write: write),
                  MyActivityView(read: read, write: write),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (BuildContext ctx) => FloatingActionButton.extended(
            backgroundColor: ColorTokens.surface,
            foregroundColor: AppAccent.of(context).accent,
            onPressed: () => showWriteOnWebNotice(
              ctx,
              shortform: DefaultTabController.of(ctx).index == 0,
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('작성'),
          ),
        ),
      ),
    );
  }
}
