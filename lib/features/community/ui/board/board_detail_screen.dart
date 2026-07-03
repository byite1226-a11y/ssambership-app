import 'package:flutter/material.dart';

import '../../../../design/role_accent.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/shape_tokens.dart';
import '../../../../design/spacing_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/app_badge.dart';
import '../../../../design/widgets/initial_avatar.dart';
import '../../../../shared/format/formatters.dart';
import '../../data/community_labels.dart';
import '../../data/community_models.dart';
import '../../data/community_read_repository.dart';
import '../../data/community_write_repository.dart';
import '../widgets/comment_tile.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/report_sheet.dart';

/// 게시판 상세 — 본문 + 반응(좋아요·스크랩·신고) + 댓글(읽기+작성).
/// ★ 작성은 '댓글'만 앱에서. 글 본문 편집/작성은 없음(웹).
class BoardDetailScreen extends StatefulWidget {
  const BoardDetailScreen({
    super.key,
    required this.post,
    required this.read,
    required this.write,
  });

  final BoardPost post;
  final CommunityReadRepository read;
  final CommunityWriteRepository write;

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
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
    _comments = widget.read.comments(CommunityPostType.board, widget.post.id);
    _loadReactionState();
    // 상세 진입 시 조회수 +1(진입당 1회). RPC 부재 시 조용히 무시.
    widget.write.incrementBoardView(widget.post.id);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadReactionState() async {
    try {
      final Set<String> liked = await widget.read
          .myBoardReactionIds(CommunityWriteRepository.reactionLike);
      final Set<String> scrap = await widget.read
          .myBoardReactionIds(CommunityWriteRepository.reactionScrap);
      if (!mounted) return;
      setState(() {
        _liked = liked.contains(widget.post.id);
        _scrapped = scrap.contains(widget.post.id);
      });
    } catch (_) {
      // 반응 상태 조회 실패는 화면을 막지 않는다(기본 미반응).
    }
  }

  Future<void> _toggleLike() async {
    final bool next = !_liked;
    setState(() {
      _liked = next;
      _likeCount += next ? 1 : -1;
    });
    try {
      await widget.write.toggleBoardReaction(
        postId: widget.post.id,
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
      await widget.write.toggleBoardReaction(
        postId: widget.post.id,
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
        targetType: 'community_post',
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
        postType: CommunityPostType.board,
        postId: widget.post.id,
        body: body,
      );
      _input.clear();
      setState(() {
        _comments =
            widget.read.comments(CommunityPostType.board, widget.post.id);
      });
    } catch (e) {
      _snack('댓글 등록에 실패했어요. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final BoardPost p = widget.post;
    return Scaffold(
      appBar: AppBar(title: const Text('게시글')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AppBadge(
                        label: communityCategoryLabel(p.category), tinted: true),
                    const Spacer(),
                    Text(Formatters.relativeKorean(p.createdAt),
                        style: AppType.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.titleBody),
                Text(p.title, style: AppType.title),
                const SizedBox(height: AppSpacing.titleBody),
                Row(
                  children: <Widget>[
                    InitialAvatar(name: p.authorName, size: 28, tinted: false),
                    const SizedBox(width: 8),
                    Text(p.authorName, style: AppType.caption),
                    const SizedBox(width: 10),
                    Text('조회 ${p.viewCount}', style: AppType.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  p.body?.trim().isNotEmpty == true ? p.body!.trim() : '(내용 없음)',
                  style: AppType.body,
                ),
                const SizedBox(height: AppSpacing.s24),
                ReactionBar(
                  liked: _liked,
                  scrapped: _scrapped,
                  likeCount: _likeCount,
                  commentCount: p.commentCount,
                  onToggleLike: _toggleLike,
                  onToggleScrap: _toggleScrap,
                  onReport: _report,
                ),
                const Divider(height: 28, color: ColorTokens.border),
                _commentList(),
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
          return Text('댓글을 불러오지 못했어요.', style: AppType.caption);
        }
        final List<CommunityComment> comments =
            snap.data ?? <CommunityComment>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 헤더: "댓글 {개수}"(동적 — 현재 리스트 length). 스타일 title.
            Text('댓글 ${comments.length}', style: AppType.title),
            const SizedBox(height: AppSpacing.titleBody),
            if (comments.isEmpty)
              Text('첫 댓글을 남겨보세요.', style: AppType.caption)
            else
              // 댓글 항목 '사이에만' 옅은 구분선(첫 위·마지막 아래 없음).
              for (int i = 0; i < comments.length; i++) ...<Widget>[
                if (i > 0)
                  const Divider(
                      height: 1, thickness: 0.5, color: ColorTokens.border),
                CommentTile(comment: comments[i]),
              ],
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
                style: AppType.body,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: '댓글 입력',
                  filled: true,
                  fillColor: ColorTokens.elevated,
                  border: OutlineInputBorder(
                    borderRadius: AppShape.inputRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded,
                  color: _busy ? ColorTokens.muted : AppAccent.of(context).accent),
              onPressed: _busy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
