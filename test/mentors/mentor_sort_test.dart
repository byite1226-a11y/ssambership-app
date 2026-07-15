import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mentors/data/mentor_models.dart';
import 'package:ssambership_app/features/mentors/data/mentor_sort.dart';

MentorListItem _m(
  String id, {
  DateTime? created,
  int? priceCents,
  double? rating,
  int reviews = 0,
}) =>
    MentorListItem(
      id: id,
      nickname: id,
      createdAt: created,
      plans: priceCents == null
          ? const <MentorPlan>[]
          : <MentorPlan>[MentorPlan(planTier: 'limited', amountCents: priceCents)],
      avgRating: rating,
      reviewCount: reviews,
    );

List<String> _ids(List<MentorListItem> l) =>
    l.map((MentorListItem e) => e.id).toList();

void main() {
  final MentorListItem a = _m('a',
      created: DateTime(2026, 1, 1), priceCents: 3000000, rating: 4.0, reviews: 10);
  final MentorListItem b = _m('b',
      created: DateTime(2026, 3, 1), priceCents: 1000000, rating: 5.0, reviews: 2);
  final MentorListItem c = _m('c', created: DateTime(2026, 2, 1)); // 값 없음(가격·평점 X)
  final List<MentorListItem> src = <MentorListItem>[a, b, c];

  test('최신순: createdAt 내림차순', () {
    expect(_ids(sortMentors(src, MentorSort.latest)), <String>['b', 'c', 'a']);
  });

  test('가격낮은순: minPlan 오름차순, 요금제 없음은 뒤', () {
    expect(_ids(sortMentors(src, MentorSort.priceLow)), <String>['b', 'a', 'c']);
  });

  test('별점높은순: avgRating 내림차순, 리뷰 없음은 뒤', () {
    expect(_ids(sortMentors(src, MentorSort.ratingHigh)), <String>['b', 'a', 'c']);
  });

  test('리뷰많은순: reviewCount 내림차순', () {
    expect(_ids(sortMentors(src, MentorSort.reviewMany)), <String>['a', 'b', 'c']);
  });

  test('입력 리스트는 불변(새 리스트 반환)', () {
    sortMentors(src, MentorSort.reviewMany);
    expect(_ids(src), <String>['a', 'b', 'c']);
  });

  test('라벨 4종', () {
    expect(mentorSortLabel(MentorSort.latest), '최신순');
    expect(mentorSortLabel(MentorSort.priceLow), '가격낮은순');
    expect(mentorSortLabel(MentorSort.ratingHigh), '별점높은순');
    expect(mentorSortLabel(MentorSort.reviewMany), '리뷰많은순');
  });
}
