import 'package:flutter/material.dart';

import '../../../../design/spacing_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/widgets/chip_scroll.dart';
import '../../../../design/widgets/empty_state.dart';
import '../../data/community_labels.dart';
import '../../data/community_models.dart';
import '../../data/community_read_repository.dart';
import '../../data/community_write_repository.dart';
import '../widgets/board_post_card.dart';
import 'board_detail_screen.dart';
import '../../../../shared/errors/friendly_error.dart';

/// 게시판 탭 — 카테고리칩 필터 + 글 리스트(최신순). 카드 탭 → 상세.
class BoardListView extends StatefulWidget {
  const BoardListView({super.key, required this.read, required this.write});

  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  @override
  State<BoardListView> createState() => BoardListViewState();
}

/// 상태를 공개해 글 작성 성공 시 바깥(커뮤니티 화면)에서 [reload]로 새로고침한다.
class BoardListViewState extends State<BoardListView> {
  static const int _pageSize = 20;

  final ScrollController _scroll = ScrollController();
  final List<BoardPost> _posts = <BoardPost>[];
  String? _category; // null = 전체
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
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  /// 첫 페이지부터 다시 로드(글 작성 직후 새 글 반영용).
  Future<void> reload() => _loadFirst();

  Future<void> _loadFirst() async {
    setState(() {
      _initialLoading = true;
      _error = null;
      _posts.clear();
      _hasMore = true;
    });
    try {
      final List<BoardPost> page = await widget.read
          .boards(category: _category, limit: _pageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page);
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
      final List<BoardPost> page = await widget.read.boards(
          category: _category, limit: _pageSize, offset: _posts.length);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false); // 추가 로드 실패는 조용히(기존 목록 유지).
    }
  }

  void _selectCategory(String? code) {
    _category = code;
    _loadFirst();
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
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('글을 불러오지 못했어요.\n${friendlyError(_error!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColorTokens.danger)),
        ),
      );
    }
    if (_posts.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_rounded,
        title: '아직 글이 없어요',
        message: '이 분류에는 글이 없어요.',
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 4, AppSpacing.screenH, 88),
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int i) {
        if (i >= _posts.length) {
          // 다음 페이지 로딩 인디케이터(끝에 도달 시 자동 로드).
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return BoardPostCard(post: _posts[i], onOpen: () => _open(_posts[i]));
      },
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
