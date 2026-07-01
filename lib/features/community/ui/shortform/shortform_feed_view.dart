import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/widgets/empty_state.dart';
import '../../data/community_models.dart';
import '../../data/community_read_repository.dart';
import '../../data/community_write_repository.dart';
import '../widgets/shortform_card.dart';
import 'shortform_detail_screen.dart';

/// 숏폼 탭 — 세로 피드(카드 스크롤). 카드 탭 → 세로 상세.
class ShortformFeedView extends StatefulWidget {
  const ShortformFeedView({super.key, required this.read, required this.write});

  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  @override
  State<ShortformFeedView> createState() => _ShortformFeedViewState();
}

class _ShortformFeedViewState extends State<ShortformFeedView> {
  late Future<List<ShortformPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.read.shortforms();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ShortformPost>>(
      future: _future,
      builder:
          (BuildContext context, AsyncSnapshot<List<ShortformPost>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('숏폼을 불러오지 못했어요.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ColorTokens.danger)),
            ),
          );
        }
        final List<ShortformPost> posts = snap.data ?? <ShortformPost>[];
        if (posts.isEmpty) {
          return const EmptyState(
            icon: Icons.play_circle_outline,
            title: '아직 숏폼이 없어요',
            message: '멘토들의 숏폼이 올라오면 여기에 표시돼요.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: posts.length,
          itemBuilder: (BuildContext context, int i) => ShortformCard(
            post: posts[i],
            onOpen: () => _open(posts[i]),
          ),
        );
      },
    );
  }

  Future<void> _open(ShortformPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShortformDetailScreen(
          post: post,
          read: widget.read,
          write: widget.write,
        ),
      ),
    );
  }
}
