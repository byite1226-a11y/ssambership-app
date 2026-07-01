import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import 'community_models.dart';

/// 커뮤니티 열람(읽기 전용). 게시판·숏폼·댓글은 공개 열람(published/visible),
/// 내 반응·내 활동은 RLS(본인 행)로 걸러진다. ★ 여기서 mutate 하지 않는다.
class CommunityReadRepository {
  const CommunityReadRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  String? get _uid => SupabaseInit.clientOrNull?.auth.currentUser?.id;

  /// 게시판 글 목록(공개=published, 최신순). category 지정 시 그 분류만.
  /// [limit] 지정 시 [offset]부터 그만큼만(페이징). null 이면 전체(하위 호환).
  Future<List<BoardPost>> boards({String? category, int? limit, int offset = 0}) async {
    dynamic q = _client
        .from('community_posts')
        .select('*')
        .eq('status', 'published');
    if (category != null && category.isNotEmpty) {
      q = q.eq('category', category);
    }
    q = q.order('created_at', ascending: false);
    if (limit != null) q = q.range(offset, offset + limit - 1);
    final List<Map<String, dynamic>> rows = await q;
    return rows.map(BoardPost.fromMap).toList();
  }

  /// 숏폼 목록(공개=published, 최신순). [limit]/[offset] 로 페이징(하위 호환: null=전체).
  Future<List<ShortformPost>> shortforms({int? limit, int offset = 0}) async {
    dynamic q = _client
        .from('shortform_posts')
        .select('*')
        .eq('status', 'published')
        .order('created_at', ascending: false);
    if (limit != null) q = q.range(offset, offset + limit - 1);
    final List<Map<String, dynamic>> rows = await q;
    return rows.map(ShortformPost.fromMap).toList();
  }

  /// 글/숏폼의 댓글(공개=visible, 대화순=오름차순). [limit]/[offset] 로 페이징(하위 호환: null=전체).
  Future<List<CommunityComment>> comments(
    CommunityPostType type,
    String postId, {
    int? limit,
    int offset = 0,
  }) async {
    dynamic q = _client
        .from('community_comments')
        .select('*')
        .eq('post_type', type.code)
        .eq('post_id', postId)
        .eq('status', 'visible')
        .order('created_at', ascending: true);
    if (limit != null) q = q.range(offset, offset + limit - 1);
    final List<Map<String, dynamic>> rows = await q;
    return rows.map(CommunityComment.fromMap).toList();
  }

  /// 내가 특정 반응(type: like|scrap)을 남긴 게시판 글 id 집합(반응 상태 표시용).
  Future<Set<String>> myBoardReactionIds(String reactionType) async {
    final String? uid = _uid;
    if (uid == null) return <String>{};
    final List<Map<String, dynamic>> rows = await _client
        .from('post_reactions')
        .select('post_id')
        .eq('user_id', uid)
        .eq('type', reactionType);
    return <String>{
      for (final Map<String, dynamic> r in rows)
        if (r['post_id'] != null) r['post_id'] as String,
    };
  }

  /// 내 활동: 내가 쓴 글 + 좋아요/스크랩한 글(읽기). 반응은 게시판 글 기준.
  Future<MyActivity> myActivity() async {
    final String? uid = _uid;
    if (uid == null) return const MyActivity();

    final List<Map<String, dynamic>> mineRows = await _client
        .from('community_posts')
        .select('*')
        .eq('author_id', uid)
        .order('created_at', ascending: false);
    final List<BoardPost> myPosts = mineRows.map(BoardPost.fromMap).toList();

    final Set<String> likedIds = await myBoardReactionIds('like');
    final Set<String> scrapIds = await myBoardReactionIds('scrap');
    final List<BoardPost> liked = await _postsByIds(likedIds);
    final List<BoardPost> scrapped = await _postsByIds(scrapIds);

    return MyActivity(myPosts: myPosts, liked: liked, scrapped: scrapped);
  }

  Future<List<BoardPost>> _postsByIds(Set<String> ids) async {
    if (ids.isEmpty) return <BoardPost>[];
    final List<Map<String, dynamic>> rows = await _client
        .from('community_posts')
        .select('*')
        .inFilter('id', ids.toList())
        .order('created_at', ascending: false);
    return rows.map(BoardPost.fromMap).toList();
  }
}
