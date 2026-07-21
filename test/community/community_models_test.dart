import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/community/data/community_models.dart';

/// 모델 파싱·표시명 폴백(순수). 내부 id 노출 없음, author_label 우선.
void main() {
  group('communityAuthorName 폴백', () {
    test('author_label 우선', () {
      expect(communityAuthorName('익명1', 'student'), '익명1');
    });
    test('label 비면 역할 라벨(mentor→멘토, student→학생)', () {
      expect(communityAuthorName('', 'mentor'), '멘토');
      expect(communityAuthorName(null, 'student'), '학생');
    });
    test('둘 다 없으면 "쌤버십 회원"', () {
      expect(communityAuthorName(null, null), '쌤버십 회원');
    });
  });

  test('BoardPost.fromMap: content 우선 본문, 카운트 파싱, 제목 폴백', () {
    final BoardPost p = BoardPost.fromMap(<String, dynamic>{
      'id': 'b1',
      'title': '',
      'content': '본문',
      'body': 'ignored',
      'category': 'study',
      'like_count': 3,
      'comment_count': 7,
      'view_count': 100,
      'author_label': '익명1',
      'author_role': 'student',
      'created_at': '2026-06-28T00:00:00Z',
    });
    expect(p.title, '(제목 없음)'); // 빈 제목 폴백
    expect(p.body, '본문'); // content 우선
    expect(p.likeCount, 3);
    expect(p.commentCount, 7);
    expect(p.authorName, '익명1');
  });

  test('ShortformPost.fromMap: 썸네일/조회수/좋아요 파싱', () {
    final ShortformPost s = ShortformPost.fromMap(<String, dynamic>{
      'id': 's1',
      'title': '숏폼',
      'thumbnail_url': 'http://x/y.jpg',
      'video_url': 'http://x/y.mp4',
      'like_count': 5,
      'view_count': 69,
      'author_role': 'mentor',
      'created_at': '2026-06-28T00:00:00Z',
    });
    expect(s.title, '숏폼');
    expect(s.thumbnailUrl, 'http://x/y.jpg');
    expect(s.likeCount, 5);
    expect(s.viewCount, 69);
  });

  group('ShortformPost.fromMap 본문 우선순위(서버 계약: body 우선·content 폴백)', () {
    Map<String, dynamic> row({String? body, String? content, String? desc}) =>
        <String, dynamic>{
          'id': 's1',
          'title': '숏폼',
          if (body != null) 'body': body,
          if (content != null) 'content': content,
          if (desc != null) 'description': desc,
          'created_at': '2026-06-28T00:00:00Z',
        };

    test('body 가 있으면 body(다른 컬럼 무시)', () {
      final ShortformPost s = ShortformPost.fromMap(
          row(body: '본문', content: 'legacy', desc: '구설명'));
      expect(s.description, '본문');
    });

    test('body 가 비면 legacy content 폴백', () {
      final ShortformPost s = ShortformPost.fromMap(
          row(body: '  ', content: 'legacy', desc: '구설명'));
      expect(s.description, 'legacy');
    });

    test('body/content 모두 없으면 구 description 컬럼(최종 폴백)', () {
      final ShortformPost s = ShortformPost.fromMap(row(desc: '구설명'));
      expect(s.description, '구설명');
    });

    test('셋 다 없으면 null', () {
      expect(ShortformPost.fromMap(row()).description, isNull);
    });
  });

  test('CommunityPostType.code', () {
    expect(CommunityPostType.board.code, 'board');
    expect(CommunityPostType.shortform.code, 'shortform');
  });
}
