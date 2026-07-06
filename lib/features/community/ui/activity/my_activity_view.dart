import 'package:flutter/material.dart';

import '../../../../design/spacing_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/empty_state.dart';
import '../../data/community_models.dart';
import '../../data/community_read_repository.dart';
import '../../data/community_write_repository.dart';
import '../board/board_detail_screen.dart';
import '../widgets/board_post_card.dart';
import '../../../../shared/errors/friendly_error.dart';

/// 내 활동 탭 — 내가 쓴 글 / 좋아요 / 스크랩(읽기). 카드 탭 → 상세.
class MyActivityView extends StatefulWidget {
  const MyActivityView({super.key, required this.read, required this.write});

  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  @override
  State<MyActivityView> createState() => _MyActivityViewState();
}

class _MyActivityViewState extends State<MyActivityView> {
  late Future<MyActivity> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.read.myActivity();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyActivity>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<MyActivity> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('내 활동을 불러오지 못했어요.\n${friendlyError(snap.error!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ColorTokens.danger)),
            ),
          );
        }
        final MyActivity a = snap.data ?? const MyActivity();
        if (a.isEmpty) {
          return const EmptyState(
            icon: Icons.history_outlined,
            title: '아직 활동이 없어요',
            message: '글에 좋아요·스크랩하거나 웹에서 글을 쓰면 여기에 모여요.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, 12, AppSpacing.screenH, 24),
          children: <Widget>[
            _group('내가 쓴 글', a.myPosts),
            _group('좋아요한 글', a.liked),
            _group('스크랩한 글', a.scrapped),
          ],
        );
      },
    );
  }

  Widget _group(String title, List<BoardPost> posts) {
    if (posts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6, bottom: 8),
          child: Text(title, style: AppType.caption),
        ),
        for (final BoardPost p in posts) ...<Widget>[
          BoardPostCard(post: p, onOpen: () => _open(p)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _open(BoardPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardDetailScreen(
          post: post,
          read: widget.read,
          write: widget.write,
        ),
      ),
    );
  }
}
