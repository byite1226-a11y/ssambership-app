import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/widgets/chip_scroll.dart';
import '../../../../design/widgets/empty_state.dart';
import '../../data/community_labels.dart';
import '../../data/community_models.dart';
import '../../data/community_read_repository.dart';
import '../../data/community_write_repository.dart';
import '../widgets/board_post_card.dart';
import 'board_detail_screen.dart';

/// 게시판 탭 — 카테고리칩 필터 + 글 리스트(최신순). 카드 탭 → 상세.
class BoardListView extends StatefulWidget {
  const BoardListView({super.key, required this.read, required this.write});

  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  @override
  State<BoardListView> createState() => _BoardListViewState();
}

class _BoardListViewState extends State<BoardListView> {
  late Future<List<BoardPost>> _future;
  String? _category; // null = 전체

  @override
  void initState() {
    super.initState();
    _future = widget.read.boards();
  }

  void _selectCategory(String? code) {
    setState(() {
      _category = code;
      _future = widget.read.boards(category: code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      '전체',
      for (final MapEntry<String, String> e in communityCategoryOptions) e.value,
    ];
    final int selected = _category == null
        ? 0
        : communityCategoryOptions
                .indexWhere((MapEntry<String, String> e) => e.key == _category) +
            1;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: ChipScroll(
            labels: labels,
            selectedIndex: selected < 0 ? 0 : selected,
            onSelected: (int i) => _selectCategory(
                i == 0 ? null : communityCategoryOptions[i - 1].key),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<BoardPost>>(
            future: _future,
            builder:
                (BuildContext context, AsyncSnapshot<List<BoardPost>> snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('글을 불러오지 못했어요.\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ColorTokens.danger)),
                  ),
                );
              }
              final List<BoardPost> posts = snap.data ?? <BoardPost>[];
              if (posts.isEmpty) {
                return const EmptyState(
                  icon: Icons.forum_outlined,
                  title: '아직 글이 없어요',
                  message: '이 분류에는 글이 없어요.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int i) => BoardPostCard(
                  post: posts[i],
                  onOpen: () => _open(posts[i]),
                ),
              );
            },
          ),
        ),
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
