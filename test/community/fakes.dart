import 'package:ssambership_app/features/community/data/community_models.dart';
import 'package:ssambership_app/features/community/data/community_read_repository.dart';
import 'package:ssambership_app/features/community/data/community_write_repository.dart';

/// 실제 DB·네트워크 대신 주입할 가짜 레포. 고정 데이터만 반환(Supabase 미접촉).
class FakeCommunityRead extends CommunityReadRepository {
  const FakeCommunityRead({
    this.boardsList = const <BoardPost>[],
    this.shortformsList = const <ShortformPost>[],
    this.commentsList = const <CommunityComment>[],
    this.activity = const MyActivity(),
  });

  final List<BoardPost> boardsList;
  final List<ShortformPost> shortformsList;
  final List<CommunityComment> commentsList;
  final MyActivity activity;

  /// 실제 repo 와 같은 페이지 계약: nextOffset 은 필터 전 행 수 기준(여긴 필터 없음).
  CommunityPage<T> _page<T>(List<T> all, int? limit, int offset) {
    final List<T> items;
    if (limit == null) {
      items = all;
    } else {
      final int start = offset.clamp(0, all.length);
      final int end = (offset + limit).clamp(0, all.length);
      items = all.sublist(start, end);
    }
    return CommunityPage<T>(
      items: items,
      rawCount: items.length,
      nextOffset: offset + items.length,
      hasMore: limit != null && items.length == limit,
    );
  }

  @override
  Future<CommunityPage<BoardPost>> boards(
      {String? category, int? limit, int offset = 0}) async {
    final List<BoardPost> all = category == null
        ? boardsList
        : boardsList.where((BoardPost p) => p.category == category).toList();
    return _page<BoardPost>(all, limit, offset);
  }

  @override
  Future<CommunityPage<ShortformPost>> shortforms(
      {int? limit, int offset = 0}) async {
    return _page<ShortformPost>(shortformsList, limit, offset);
  }

  @override
  Future<List<CommunityComment>> comments(CommunityPostType type, String postId,
          {int? limit, int offset = 0}) async =>
      commentsList;

  @override
  Future<Set<String>> myBoardReactionIds(String reactionType) async =>
      <String>{};

  @override
  Future<Set<String>> myShortformReactionIds(String reactionType) async =>
      <String>{};

  @override
  Future<MyActivity> myActivity() async => activity;
}

/// 반응·댓글·신고 쓰기를 삼키는 가짜 레포(호출 기록만).
/// [failReactions] 로 반응 토글 실패(서버 오류)를 흉내낼 수 있다(낙관적 롤백 검증용).
class FakeCommunityWrite extends CommunityWriteRepository {
  FakeCommunityWrite();

  int reactionCalls = 0;
  int commentCalls = 0;
  int reportCalls = 0;
  int postCalls = 0;
  String? lastReportReason;
  String? lastPostTitle;
  String? lastPostBody;
  String? lastPostCategory;

  /// true 면 반응 토글이 호출 기록 후 throw(낙관적 상태 롤백 경로 테스트).
  bool failReactions = false;

  /// 반응 토글 호출 로그('like:on' 형식) — like/scrap 독립성 검증용.
  final List<String> reactionLog = <String>[];

  @override
  Future<void> toggleBoardReaction({
    required String postId,
    required String type,
    required bool on,
  }) async {
    reactionCalls++;
    reactionLog.add('$type:${on ? 'on' : 'off'}');
    if (failReactions) throw Exception('reaction failed');
  }

  @override
  Future<void> toggleShortformReaction({
    required String shortformId,
    required String type,
    required bool on,
  }) async {
    reactionCalls++;
    reactionLog.add('$type:${on ? 'on' : 'off'}');
    if (failReactions) throw Exception('reaction failed');
  }

  @override
  Future<CommunityComment> addComment({
    required CommunityPostType postType,
    required String postId,
    required String body,
  }) async {
    commentCalls++;
    return CommunityComment(
      id: 'fake-comment',
      body: body,
      authorLabel: '나',
      createdAt: DateTime(2026, 7, 1),
    );
  }

  @override
  Future<BoardPost> createPost({
    required String title,
    required String body,
    required String category,
  }) async {
    postCalls++;
    lastPostTitle = title;
    lastPostBody = body;
    lastPostCategory = category;
    return BoardPost(
      id: 'fake-post',
      title: title,
      body: body,
      category: category,
      authorLabel: '나',
      authorRole: 'student',
      likeCount: 0,
      commentCount: 0,
      viewCount: 0,
      createdAt: DateTime(2026, 7, 1),
    );
  }

  @override
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    reportCalls++;
    lastReportReason = reason;
  }
}

/// 샘플 데이터 빌더.
BoardPost sampleBoard({
  String id = 'b1',
  String title = '게시판 제목',
  String category = 'study',
  int likeCount = 3,
  int commentCount = 7,
  int viewCount = 100,
}) {
  return BoardPost(
    id: id,
    title: title,
    body: '본문 내용입니다.',
    category: category,
    authorLabel: '익명1',
    authorRole: 'student',
    likeCount: likeCount,
    commentCount: commentCount,
    viewCount: viewCount,
    createdAt: DateTime(2026, 6, 28),
  );
}

ShortformPost sampleShortform({
  String id = 's1',
  String title = '숏폼 제목',
  String? videoUrl, // null=썸네일 폴백, 지정 시 재생 경로 테스트
  int likeCount = 5,
  int viewCount = 69,
}) {
  return ShortformPost(
    id: id,
    title: title,
    description: '숏폼 설명',
    category: 'study',
    authorLabel: '멘토쌤',
    authorRole: 'mentor',
    thumbnailUrl: null, // 네트워크 미사용(폴백 렌더)
    videoUrl: videoUrl,
    likeCount: likeCount,
    viewCount: viewCount,
    createdAt: DateTime(2026, 6, 28),
  );
}

CommunityComment sampleComment({String body = '좋은 글이에요.'}) {
  return CommunityComment(
    id: 'c1',
    body: body,
    authorLabel: '익명2',
    createdAt: DateTime(2026, 6, 29),
  );
}
