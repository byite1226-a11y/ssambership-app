import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mentors/data/mentor_models.dart';

/// 멘토 상세 '활동' 통계 표시 규칙(순수 getter — DB·네트워크 미접촉).
/// 값이 없으면 날조하지 않고 빈 처리로 폴백하는지 검증.
void main() {
  test('공개 리뷰 있음 → 평점 라벨 + 응답 라벨, 빈 상태 아님', () {
    const MentorDetailExtras e = MentorDetailExtras(
      avgRating: 4.5,
      reviewCount: 2,
      avgResponseHours: 3,
    );
    expect(e.ratingLabel, '4.5  ·  리뷰 2개');
    expect(e.responseLabel, '평균 답변 약 3시간');
    expect(e.hasNoActivity, isFalse);
  });

  test('리뷰 없음(count 0 / avg null) → 평점 라벨 null', () {
    const MentorDetailExtras e =
        MentorDetailExtras(avgRating: null, reviewCount: 0);
    expect(e.ratingLabel, isNull);
    // 평점·응답 모두 없으면 빈 상태.
    expect(e.hasNoActivity, isTrue);
  });

  test('응답시간만 있으면 응답 라벨만, 빈 상태 아님', () {
    const MentorDetailExtras e = MentorDetailExtras(avgResponseHours: 0.5);
    expect(e.ratingLabel, isNull);
    expect(e.responseLabel, '평균 답변 1시간 이내');
    expect(e.hasNoActivity, isFalse);
  });

  test('평점만 있고 응답시간 없으면 평점 라벨만', () {
    const MentorDetailExtras e =
        MentorDetailExtras(avgRating: 5, reviewCount: 1);
    expect(e.ratingLabel, '5.0  ·  리뷰 1개');
    expect(e.responseLabel, isNull);
    expect(e.hasNoActivity, isFalse);
  });
}
