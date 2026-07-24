import 'package:flutter/material.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/web_bridge/shortform_compose_bridge.dart';
import '../../../../design/spacing_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/widgets/empty_state.dart';
import '../../../../design/widgets/primary_button.dart';
import '../../data/community_models.dart';
import '../../data/community_paginator.dart';
import '../../data/community_read_repository.dart';
import '../../data/community_write_repository.dart';
import '../widgets/shortform_card.dart';
import 'shortform_compose_screen.dart';
import 'shortform_detail_screen.dart';
import '../../../../shared/errors/friendly_error.dart';

/// 숏폼 탭 — 세로 피드(카드 스크롤). 카드 탭 → 세로 상세.
/// 페이징·세대(스테일 응답 폐기)는 [CommunityPaginator] 가 관리(P2-21).
///
/// 작성: 멘토에게만 '숏폼 작성' CTA 를 노출한다 — 실제 작성은 비결제 전용
/// 인앱 WebView([ShortformComposeScreen], 웹 작성기 계약)가 담당한다.
/// 학생·게스트는 열람·좋아요·찜·댓글만(기존 유지).
class ShortformFeedView extends StatefulWidget {
  const ShortformFeedView({
    super.key,
    required this.read,
    required this.write,
    this.roleOf = _defaultRoleOf,
  });

  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  /// 현재 역할 판정(테스트 주입용). 기본은 [AuthService] 단일 소스.
  final AppRole Function() roleOf;

  static AppRole _defaultRoleOf() => AuthService.instance.currentRole;

  @override
  State<ShortformFeedView> createState() => _ShortformFeedViewState();
}

class _ShortformFeedViewState extends State<ShortformFeedView> {
  static const int _pageSize = 20;

  final ScrollController _scroll = ScrollController();
  late final CommunityPaginator<ShortformPost> _pager;

  @override
  void initState() {
    super.initState();
    _pager = CommunityPaginator<ShortformPost>(
      fetch: (int offset, int limit) =>
          widget.read.shortforms(limit: limit, offset: offset),
      pageSize: _pageSize,
    );
    _scroll.addListener(_onScroll);
    _pager.refresh();
  }

  @override
  void dispose() {
    _pager.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _pager.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _pager,
      builder: (BuildContext context, _) => _body(),
    );
  }

  Widget _body() {
    final bool canCompose = widget.roleOf() == AppRole.mentor;
    if (_pager.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pager.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('숏폼을 불러오지 못했어요.\n${friendlyError(_pager.error!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColorTokens.danger)),
        ),
      );
    }
    final List<ShortformPost> posts = _pager.items;
    if (posts.isEmpty) {
      // 멘토: 작성 유도 빈 화면. 학생·게스트: 기존 열람 안내 그대로.
      return canCompose
          ? EmptyState(
              icon: Icons.play_circle_outline,
              title: '아직 숏폼이 없어요',
              message: '앱 안에서 영상을 선택해 작성할 수 있어요.',
              actionLabel: '숏폼 작성',
              onAction: _openCompose,
            )
          : const EmptyState(
              icon: Icons.play_circle_outline,
              title: '아직 숏폼이 없어요',
              message: '멘토들의 숏폼이 올라오면 여기에 표시돼요.',
            );
    }
    final Widget list = ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 8, AppSpacing.screenH, 88),
      itemCount: posts.length + (_pager.hasMore ? 1 : 0),
      itemBuilder: (BuildContext context, int i) {
        if (i >= posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ShortformCard(post: posts[i], onOpen: () => _open(posts[i]));
      },
    );
    if (!canCompose) return list;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, 8, AppSpacing.screenH, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: '숏폼 작성',
              onPressed: _openCompose,
              expand: false,
            ),
          ),
        ),
        Expanded(child: list),
      ],
    );
  }

  /// 작성 WebView 열기 → 완료 결과에 따라 피드 '서버 재조회'(로컬 가짜 카드 금지).
  Future<void> _openCompose() async {
    final ShortformComposeResult? result =
        await Navigator.of(context).push<ShortformComposeResult>(
      MaterialPageRoute<ShortformComposeResult>(
        builder: (_) => const ShortformComposeScreen(),
      ),
    );
    if (!mounted || result == null) return;
    _pager.refresh(); // published/draft 모두 서버 기준으로 다시 읽는다.
    if (result == ShortformComposeResult.draft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('임시저장됐어요')),
      );
    }
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
