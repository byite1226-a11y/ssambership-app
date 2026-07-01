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
  static const int _pageSize = 20;

  final ScrollController _scroll = ScrollController();
  final List<ShortformPost> _posts = <ShortformPost>[];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    try {
      final List<ShortformPost> page =
          await widget.read.shortforms(limit: _pageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(page);
        _hasMore = page.length == _pageSize;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoading) return;
    setState(() => _loadingMore = true);
    try {
      final List<ShortformPost> page =
          await widget.read.shortforms(limit: _pageSize, offset: _posts.length);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('숏폼을 불러오지 못했어요.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColorTokens.danger)),
        ),
      );
    }
    if (_posts.isEmpty) {
      return const EmptyState(
        icon: Icons.play_circle_outline,
        title: '아직 숏폼이 없어요',
        message: '멘토들의 숏폼이 올라오면 여기에 표시돼요.',
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      itemBuilder: (BuildContext context, int i) {
        if (i >= _posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ShortformCard(post: _posts[i], onOpen: () => _open(_posts[i]));
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
