import 'package:flutter/material.dart';

import '../../../../design/role_accent.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../data/community_models.dart';
import '../../data/community_read_repository.dart';
import '../../data/community_write_repository.dart';
import '../widgets/comment_tile.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/report_sheet.dart';
import '../widgets/thumbnail_view.dart';

/// 숏폼 상세 — 세로 영상 영역(썸네일+재생 어포던스) + 반응 + 댓글.
/// ★ 실제 영상 재생 플러그인 없음(썸네일/재생 아이콘). 작성은 '댓글'만.
class ShortformDetailScreen extends StatefulWidget {
  const ShortformDetailScreen({
    super.key,
    required this.post,
    required this.read,
    required this.write,
  });

  final ShortformPost post;
  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  @override
  State<ShortformDetailScreen> createState() => _ShortformDetailScreenState();
}

class _ShortformDetailScreenState extends State<ShortformDetailScreen> {
  final TextEditingController _input = TextEditingController();
  late Future<List<CommunityComment>> _comments;

  bool _liked = false;
  bool _scrapped = false;
  late int _likeCount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _comments =
        widget.read.comments(CommunityPostType.shortform, widget.post.id);
    _loadReactionState();
    // 상세 진입 시 조회수 +1(진입당 1회). RPC 부재 시 조용히 무시.
    widget.write.incrementShortformView(widget.post.id);
  }

  /// 현재 사용자의 기존 숏폼 반응(좋아요/스크랩)을 로드해 초기 상태에 반영(게시판과 동일 패턴).
  Future<void> _loadReactionState() async {
    try {
      final Set<String> liked = await widget.read
          .myShortformReactionIds(CommunityWriteRepository.reactionLike);
      final Set<String> scrap = await widget.read
          .myShortformReactionIds(CommunityWriteRepository.reactionScrap);
      if (!mounted) return;
      setState(() {
        _liked = liked.contains(widget.post.id);
        _scrapped = scrap.contains(widget.post.id);
      });
    } catch (_) {
      // 반응 상태 조회 실패는 화면을 막지 않는다(기본 미반응).
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final bool next = !_liked;
    setState(() {
      _liked = next;
      _likeCount += next ? 1 : -1;
    });
    try {
      await widget.write.toggleShortformReaction(
        shortformId: widget.post.id,
        type: CommunityWriteRepository.reactionLike,
        on: next,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = !next;
        _likeCount += next ? -1 : 1;
      });
      _snack('반응 처리에 실패했어요. ($e)');
    }
  }

  Future<void> _toggleScrap() async {
    final bool next = !_scrapped;
    setState(() => _scrapped = next);
    try {
      await widget.write.toggleShortformReaction(
        shortformId: widget.post.id,
        type: CommunityWriteRepository.reactionScrap,
        on: next,
      );
      _snack(next ? '스크랩했어요.' : '스크랩을 해제했어요.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _scrapped = !next);
      _snack('처리에 실패했어요. ($e)');
    }
  }

  Future<void> _report() async {
    final String? reason = await showReportSheet(context);
    if (reason == null) return;
    try {
      await widget.write.report(
        targetType: 'shortform',
        targetId: widget.post.id,
        reason: reason,
      );
      _snack('신고가 접수되었어요. 운영팀이 검토할게요.');
    } catch (e) {
      _snack('신고 접수에 실패했어요. ($e)');
    }
  }

  Future<void> _send() async {
    final String body = _input.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.write.addComment(
        postType: CommunityPostType.shortform,
        postId: widget.post.id,
        body: body,
      );
      _input.clear();
      setState(() {
        _comments =
            widget.read.comments(CommunityPostType.shortform, widget.post.id);
      });
    } catch (e) {
      _snack('댓글 등록에 실패했어요. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ShortformPost p = widget.post;
    return Scaffold(
      appBar: AppBar(title: const Text('숏폼')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // 세로 영상 영역(9:16). 실제 재생 대신 썸네일+재생 아이콘.
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ThumbnailView(url: p.thumbnailUrl, playable: true),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          if (p.authorRole == 'mentor')
                            const AppBadge(label: '멘토', tinted: true),
                          if (p.authorRole == 'mentor')
                            const SizedBox(width: 6),
                          Text(p.authorName, style: AppTypography.caption),
                          const Spacer(),
                          Text('조회 ${p.viewCount}',
                              style: AppTypography.caption),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.title, style: AppTypography.title),
                      if (p.description?.trim().isNotEmpty == true) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(p.description!.trim(), style: AppTypography.body),
                      ],
                      const SizedBox(height: 16),
                      ReactionBar(
                        liked: _liked,
                        scrapped: _scrapped,
                        likeCount: _likeCount,
                        commentCount: 0,
                        onToggleLike: _toggleLike,
                        onToggleScrap: _toggleScrap,
                        onReport: _report,
                      ),
                      const Divider(height: 28, color: ColorTokens.border),
                      Text('댓글', style: AppTypography.caption),
                      const SizedBox(height: 6),
                      _commentList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _commentList() {
    return FutureBuilder<List<CommunityComment>>(
      future: _comments,
      builder:
          (BuildContext context, AsyncSnapshot<List<CommunityComment>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Text('댓글을 불러오지 못했어요.', style: AppTypography.caption);
        }
        final List<CommunityComment> comments =
            snap.data ?? <CommunityComment>[];
        if (comments.isEmpty) {
          return Text('첫 댓글을 남겨보세요.', style: AppTypography.caption);
        }
        return Column(
          children: <Widget>[
            for (final CommunityComment c in comments) CommentTile(comment: c),
          ],
        );
      },
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: ColorTokens.surface,
          border: Border(top: BorderSide(color: ColorTokens.border)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _input,
                style: AppTypography.body,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: '댓글 입력',
                  filled: true,
                  fillColor: ColorTokens.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send,
                  color: _busy ? ColorTokens.muted : AppAccent.of(context).accent),
              onPressed: _busy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
