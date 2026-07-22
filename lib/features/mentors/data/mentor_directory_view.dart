import 'mentor_models.dart';
import 'mentor_sort.dart';
import 'mentor_subject.dart';

/// 멘토 찾기 화면의 순수(테스트 가능) 뷰 로직 — 위젯 상태에 의존하지 않는다.
///
/// 검색·과목 필터·정렬은 모두 **전체 로드 집합**에 적용한다(최신 N명 창 검색 금지).

/// 상단 과목 필터 칩 목록.
///
/// 전체 로드 집합의 모든 멘토 과목을 canonical [MentorSubject.key] 기준으로 중복
/// 제거하고, **표시 라벨 기준 안정 정렬**(동률은 최초 등장 순서 유지)한다. 칩에는
/// 한글 라벨만 노출된다(코드 문자열순 아님).
List<MentorSubject> distinctSubjects(List<MentorListItem> all) {
  final List<MentorSubject> collected = <MentorSubject>[];
  final Set<String> seen = <String>{};
  for (final MentorListItem m in all) {
    for (final MentorSubject s in m.subjectViews) {
      if (seen.add(s.key)) collected.add(s);
    }
  }
  // 표시 라벨 기준 안정 정렬: 등장 순서를 tie-breaker 로 써서 List.sort 불안정성을 상쇄.
  final List<int> order = <int>[for (int i = 0; i < collected.length; i++) i];
  order.sort((int a, int b) {
    final int c = collected[a].label.compareTo(collected[b].label);
    return c != 0 ? c : a.compareTo(b);
  });
  return <MentorSubject>[for (final int i in order) collected[i]];
}

/// 검색·과목 필터·정렬을 전체 로드 집합에 적용한 결과.
///
/// - [subjectKey] : canonical key(=[MentorSubject.key]). null 이면 과목 필터 없음.
/// - [query]      : 이름·학교·학과·과목(raw+라벨) 매칭. 대소문자 구분 없음.
List<MentorListItem> filterSearchSortMentors({
  required List<MentorListItem> all,
  String query = '',
  String? subjectKey,
  MentorSort sort = MentorSort.latest,
}) {
  Iterable<MentorListItem> it = all;
  if (subjectKey != null) {
    it = it.where(
      (MentorListItem m) =>
          m.subjectViews.any((MentorSubject s) => s.key == subjectKey),
    );
  }
  final String q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    it = it.where(
      (MentorListItem m) => m.searchHaystack.toLowerCase().contains(q),
    );
  }
  return sortMentors(it.toList(), sort);
}
