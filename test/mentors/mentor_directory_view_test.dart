import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mentors/data/mentor_directory_view.dart';
import 'package:ssambership_app/features/mentors/data/mentor_models.dart';
import 'package:ssambership_app/features/mentors/data/mentor_sort.dart';
import 'package:ssambership_app/features/mentors/data/mentor_subject.dart';

MentorListItem _m(
  String id, {
  List<String> subjects = const <String>[],
  DateTime? created,
  String? name,
  String? uni,
  String? dept,
  double? rating,
  int reviews = 0,
}) =>
    MentorListItem(
      id: id,
      nickname: name ?? id,
      createdAt: created,
      avgRating: rating,
      reviewCount: reviews,
      profile: MentorProfileInfo(
        userId: id,
        universityName: uni,
        departmentName: dept,
        teachingSubjects: subjects,
      ),
    );

List<String> _ids(List<MentorListItem> l) =>
    l.map((MentorListItem e) => e.id).toList();

void main() {
  group('distinctSubjects — canonical 칩(중복 제거·라벨 정렬)', () {
    test('수학+math 혼재 → 칩 1개, math_calculus 는 별도(미적분)', () {
      final List<MentorSubject> chips = distinctSubjects(<MentorListItem>[
        _m('a', subjects: <String>['수학']),
        _m('b', subjects: <String>['math', 'math_calculus']),
      ]);
      final List<String> labels =
          chips.map((MentorSubject s) => s.label).toList();
      expect(labels.where((String l) => l == '수학').length, 1);
      expect(labels.contains('미적분'), isTrue);
    });

    test('미지 ASCII 여러 개 → 기타 칩 1개(중복 없음)', () {
      final List<MentorSubject> chips = distinctSubjects(<MentorListItem>[
        _m('a', subjects: <String>['unknown_one']),
        _m('b', subjects: <String>['another_unknown']),
      ]);
      expect(chips.where((MentorSubject s) => s.label == '기타').length, 1);
    });

    test('칩은 표시 라벨 기준 정렬(코드 문자열순 아님)', () {
      // raw 코드 문자열순이면 english < math < science 지만, 라벨순은 과학<수학<영어.
      final List<MentorSubject> chips = distinctSubjects(<MentorListItem>[
        _m('a', subjects: <String>['english', 'math', 'science']),
      ]);
      expect(chips.map((MentorSubject s) => s.label).toList(),
          <String>['과학', '수학', '영어']);
    });
  });

  group('검색 — raw/label 모두 매칭, 대소문자 무시', () {
    final List<MentorListItem> all = <MentorListItem>[
      _m('math_mentor', subjects: <String>['math'], name: '김수학'),
      _m('calc_mentor', subjects: <String>['math_calculus'], name: '이미적'),
      _m('eng_mentor',
          subjects: <String>['english'],
          name: 'Alice',
          uni: '서울대',
          dept: '영어교육과'),
    ];

    test('한글 수학 검색 → raw math 멘토 매칭', () {
      final List<MentorListItem> out =
          filterSearchSortMentors(all: all, query: '수학');
      expect(_ids(out), contains('math_mentor'));
    });

    test('한글 미적분 검색 → raw math_calculus 멘토 매칭', () {
      final List<MentorListItem> out =
          filterSearchSortMentors(all: all, query: '미적분');
      expect(_ids(out), contains('calc_mentor'));
    });

    test('raw 코드(math) 검색도 유지', () {
      final List<MentorListItem> out =
          filterSearchSortMentors(all: all, query: 'math');
      expect(_ids(out), contains('math_mentor'));
    });

    test('영문 검색은 대소문자 무시(ENGLISH)', () {
      final List<MentorListItem> out =
          filterSearchSortMentors(all: all, query: 'ENGLISH');
      expect(_ids(out), contains('eng_mentor'));
    });

    test('이름·학교·학과 검색 회귀 없음', () {
      expect(_ids(filterSearchSortMentors(all: all, query: '김수학')),
          contains('math_mentor'));
      expect(_ids(filterSearchSortMentors(all: all, query: '서울대')),
          contains('eng_mentor'));
      expect(_ids(filterSearchSortMentors(all: all, query: '영어교육과')),
          contains('eng_mentor'));
    });
  });

  group('과목 필터 — canonical key, 전체 집합 대상', () {
    test('수학 key 필터는 raw 수학/math 를 모두 포함', () {
      final List<MentorListItem> all = <MentorListItem>[
        _m('a', subjects: <String>['수학']),
        _m('b', subjects: <String>['math']),
        _m('c', subjects: <String>['english']),
      ];
      final List<MentorListItem> out =
          filterSearchSortMentors(all: all, subjectKey: 'math');
      expect(_ids(out)..sort(), <String>['a', 'b']);
    });

    test('최신 20명 밖(가장 오래된)에 있는 매칭 멘토도 검색·필터에 포함', () {
      // 25명: 최신 24명은 영어, 가장 오래된 1명만 수학 → 최신 20 창이었다면 누락됐을 케이스.
      final List<MentorListItem> all = <MentorListItem>[
        for (int i = 0; i < 24; i++)
          _m('recent_$i',
              subjects: <String>['english'],
              created: DateTime(2026, 7, 22).subtract(Duration(days: i))),
        _m('oldest_math',
            subjects: <String>['math'], created: DateTime(2020, 1, 1)),
      ];
      // 검색: 전체 집합에서 찾음(창 제한 없음).
      expect(_ids(filterSearchSortMentors(all: all, query: '수학')),
          <String>['oldest_math']);
      // 과목 필터: 전체 집합에서 산출.
      expect(_ids(filterSearchSortMentors(all: all, subjectKey: 'math')),
          <String>['oldest_math']);
    });
  });

  group('정렬 위임 회귀', () {
    final List<MentorListItem> all = <MentorListItem>[
      _m('a', created: DateTime(2026, 1, 1), rating: 4.0, reviews: 10),
      _m('b', created: DateTime(2026, 3, 1), rating: 5.0, reviews: 2),
      _m('c', created: DateTime(2026, 2, 1)),
    ];
    test('최신순', () {
      expect(_ids(filterSearchSortMentors(all: all, sort: MentorSort.latest)),
          <String>['b', 'c', 'a']);
    });
    test('별점높은순', () {
      expect(
          _ids(filterSearchSortMentors(all: all, sort: MentorSort.ratingHigh)),
          <String>['b', 'a', 'c']);
    });
    test('리뷰많은순', () {
      expect(
          _ids(filterSearchSortMentors(all: all, sort: MentorSort.reviewMany)),
          <String>['a', 'b', 'c']);
    });
  });
}
