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

  @override
  Future<List<BoardPost>> boards(
      {String? category, int? limit, int offset = 0}) async {
    final List<BoardPost> all = category == null
        ? boardsList
        : boardsList.where((BoardPost p) => p.category == category).toList();
    if (limit == null) return all;
    final int start = offset.clamp(0, all.length);
    final int end = (offset + limit).clamp(0, all.length);
    return all.sublist(start, end);
  }

  @override
  Future<List<ShortformPost>> shortforms({int? limit, int offset = 0}) async {
    if (limit == null) return shortformsList;
    final int start = offset.clamp(0, shortformsList.length);
    final int end = (offset + limit).clamp(0, shortformsList.length);
    return shortformsList.sublist(start, end);
  }

  @override
  Future<List<CommunityComment>> comments(
          CommunityPostType type, String postId,
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
class FakeCommunityWrite extends CommunityWriteRepository {
  FakeCommunityWrite();

  int reactionCalls = 0;
  int commentCalls = 0;
  int reportCalls = 0;
  String? lastReportReason;

  @override
  Future<void> toggleBoardReaction({
    required String postId,
    required String type,
    required bool on,
  }) async {
    reactionCalls++;
  }

  @override
  Future<void> toggleShortformReaction({
    required String shortformId,
    required String type,
    required bool on,
  }) async {
    reactionCalls++;
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
    videoUrl: null,
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
