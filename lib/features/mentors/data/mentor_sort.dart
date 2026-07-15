import 'mentor_models.dart';

/// 멘토 목록 정렬 옵션 — 데이터로 뒷받침되는 것만.
/// 최신·가격은 기존 데이터, 별점·리뷰는 공개(visible) 리뷰 집계(MentorListItem에 실림).
/// popular(인기순)는 웹 정본 기본 정렬과 동일(리뷰수*10 + 평점 내림차순). XV-QUERY-2.
enum MentorSort { popular, latest, priceLow, ratingHigh, reviewMany }

String mentorSortLabel(MentorSort s) {
  switch (s) {
    case MentorSort.popular:
      return '인기순';
    case MentorSort.latest:
      return '최신순';
    case MentorSort.priceLow:
      return '가격낮은순';
    case MentorSort.ratingHigh:
      return '별점높은순';
    case MentorSort.reviewMany:
      return '리뷰많은순';
  }
}

const int _kNoPrice = 1 << 62; // 요금제 없음 → 가격순에서 뒤로.

/// 정렬된 새 리스트를 돌려준다(입력 불변). 값 없음(가격/평점 미상)은 항상 뒤로.
List<MentorListItem> sortMentors(List<MentorListItem> src, MentorSort sort) {
  final List<MentorListItem> list = <MentorListItem>[...src];
  switch (sort) {
    case MentorSort.popular:
      // 웹 정본(publicMentorsListQueries.sortKey 'popular')과 동일 점수식.
      list.sort((MentorListItem a, MentorListItem b) {
        final double sa = a.reviewCount.toDouble() * 10 + (a.avgRating ?? 0);
        final double sb = b.reviewCount.toDouble() * 10 + (b.avgRating ?? 0);
        return sb.compareTo(sa);
      });
    case MentorSort.latest:
      list.sort((MentorListItem a, MentorListItem b) {
        final DateTime ad =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bd =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    case MentorSort.priceLow:
      list.sort((MentorListItem a, MentorListItem b) {
        final int ap = a.minPlan?.amountCents ?? _kNoPrice;
        final int bp = b.minPlan?.amountCents ?? _kNoPrice;
        return ap.compareTo(bp);
      });
    case MentorSort.ratingHigh:
      list.sort((MentorListItem a, MentorListItem b) {
        final double ar = a.avgRating ?? -1;
        final double br = b.avgRating ?? -1;
        final int c = br.compareTo(ar);
        return c != 0 ? c : b.reviewCount.compareTo(a.reviewCount);
      });
    case MentorSort.reviewMany:
      list.sort((MentorListItem a, MentorListItem b) {
        final int c = b.reviewCount.compareTo(a.reviewCount);
        return c != 0 ? c : (b.avgRating ?? -1).compareTo(a.avgRating ?? -1);
      });
  }
  return list;
}
