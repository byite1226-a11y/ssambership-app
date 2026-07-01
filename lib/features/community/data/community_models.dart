import 'model_parse.dart';

/// 작성자 표시명 폴백(공통). author_label(비정규화 표시명)이 비면 역할 기반 중립 라벨.
/// ★ 내부 author_id(UUID)는 절대 노출하지 않는다.
String communityAuthorName(String? authorLabel, String? authorRole) {
  final String label = authorLabel?.trim() ?? '';
  if (label.isNotEmpty) return label;
  switch (authorRole?.trim()) {
    case 'mentor':
      return '멘토';
    case 'student':
      return '학생';
    default:
      return '쌤버십 회원';
  }
}

/// 게시판 글(community_posts). 열람 전용 뷰모델.
class BoardPost {
  const BoardPost({
    required this.id,
    required this.title,
    this.body,
    this.category,
    this.authorLabel,
    this.authorRole,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? body;
  final String? category;
  final String? authorLabel;
  final String? authorRole;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final DateTime createdAt;

  String get authorName => communityAuthorName(authorLabel, authorRole);

  factory BoardPost.fromMap(Map<String, dynamic> m) {
    return BoardPost(
      id: m['id'] as String,
      title: (m['title'] as String?)?.trim().isNotEmpty == true
          ? (m['title'] as String).trim()
          : '(제목 없음)',
      // 스키마상 body/content 둘 다 존재 — 있는 쪽을 본문으로.
      body: (m['content'] as String?)?.trim().isNotEmpty == true
          ? (m['content'] as String).trim()
          : (m['body'] as String?)?.trim(),
      category: m['category'] as String?,
      authorLabel: m['author_label'] as String?,
      authorRole: m['author_role'] as String?,
      likeCount: parseInt(m['like_count']),
      commentCount: parseInt(m['comment_count']),
      viewCount: parseInt(m['view_count']),
      createdAt: parseTime(m['created_at']),
    );
  }
}

/// 숏폼(shortform_posts). 열람 전용 뷰모델. 실제 재생 플러그인은 없음(썸네일+재생 어포던스).
class ShortformPost {
  const ShortformPost({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.authorLabel,
    this.authorRole,
    this.thumbnailUrl,
    this.videoUrl,
    required this.likeCount,
    required this.viewCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? authorLabel;
  final String? authorRole;
  final String? thumbnailUrl;
  final String? videoUrl;
  final int likeCount;
  final int viewCount;
  final DateTime createdAt;

  String get authorName => communityAuthorName(authorLabel, authorRole);

  factory ShortformPost.fromMap(Map<String, dynamic> m) {
    return ShortformPost(
      id: m['id'] as String,
      title: (m['title'] as String?)?.trim().isNotEmpty == true
          ? (m['title'] as String).trim()
          : '(제목 없음)',
      description: (m['description'] as String?)?.trim(),
      category: m['category'] as String?,
      authorLabel: m['author_label'] as String?,
      authorRole: m['author_role'] as String?,
      thumbnailUrl: (m['thumbnail_url'] as String?)?.trim(),
      videoUrl: (m['video_url'] as String?)?.trim(),
      likeCount: parseInt(m['like_count']),
      viewCount: parseInt(m['view_count']),
      createdAt: parseTime(m['created_at']),
    );
  }
}

/// 커뮤니티 댓글(community_comments). post_type 로 게시판/숏폼 공용.
class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.body,
    this.authorLabel,
    required this.createdAt,
  });

  final String id;
  final String body;
  final String? authorLabel;
  final DateTime createdAt;

  String get authorName => communityAuthorName(authorLabel, null);

  factory CommunityComment.fromMap(Map<String, dynamic> m) {
    return CommunityComment(
      id: m['id'] as String,
      body: (m['body'] as String?)?.trim() ?? '',
      authorLabel: m['author_label'] as String?,
      createdAt: parseTime(m['created_at']),
    );
  }
}

/// 게시글 종류 — 댓글/반응 대상 구분(community_comments.post_type 등).
enum CommunityPostType {
  board,
  shortform;

  String get code => this == CommunityPostType.board ? 'board' : 'shortform';
}

/// 내 활동(읽기): 내가 쓴 글·좋아요·스크랩한 글.
class MyActivity {
  const MyActivity({
    this.myPosts = const <BoardPost>[],
    this.liked = const <BoardPost>[],
    this.scrapped = const <BoardPost>[],
  });

  final List<BoardPost> myPosts;
  final List<BoardPost> liked;
  final List<BoardPost> scrapped;

  bool get isEmpty => myPosts.isEmpty && liked.isEmpty && scrapped.isEmpty;
}

