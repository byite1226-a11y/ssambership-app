/// 과목 코드(영문) → 한글 표시 매핑.
///
/// 화면에는 절대 영문 코드(math_calculus 등)를 노출하지 않는다.
/// DB/서버에서 받은 코드를 이 매핑으로 한글 라벨로 바꿔 표시한다.
/// (미정 코드는 [subjectLabel] 이 코드 대신 '기타/미분류'로 폴백)
library;

const Map<String, String> subjectLabels = <String, String>{
  // 수학
  'math_common': '수학(공통)',
  'math_algebra': '대수',
  'math_calculus': '미적분',
  'math_geometry': '기하',
  'math_statistics': '확률과 통계',
  // 국어
  'korean_common': '국어(공통)',
  'korean_reading': '독서',
  'korean_literature': '문학',
  'korean_grammar': '언어와 매체',
  // 영어
  'english_common': '영어(공통)',
  'english_reading': '영어 독해',
  'english_grammar': '영어 문법',
  // 과학
  'science_physics': '물리학',
  'science_chemistry': '화학',
  'science_biology': '생명과학',
  'science_earth': '지구과학',
  // 사회
  'social_history': '한국사',
  'social_geography': '지리',
  'social_ethics': '생활과 윤리',
  // TODO: 서버 과목 코드 카탈로그와 동기화하여 확장.
};

/// 코드 → 한글 라벨. 미정 코드는 화면에 코드 노출 대신 폴백 라벨.
String subjectLabel(String? code) {
  if (code == null || code.trim().isEmpty) return '미분류';
  return subjectLabels[code] ?? '기타';
}

/// 질문 작성 시 노출할 과목 후보 코드.
///
/// 멘토의 담당 과목(mentor_profiles.teaching_subjects, 코드 배열) 중 **앱이 한글
/// 라벨을 아는 코드만** 후보로 제한한다(영문 코드/‘기타’ 남발 방지). 하나도 없으면
/// (빈 값·전부 미매핑·조회 실패) **전체 과목으로 폴백**한다 — 웹과 동일하게
/// "멘토 지정 과목이 있으면 제한, 없으면 전체 허용"이며 절대 빈 드롭다운으로 막지 않는다.
///
/// ★ 새 매핑을 만들지 않고 기존 [subjectLabels] 만 재사용한다. (subject_labels 는
///   서버 subjects 카탈로그의 부분 집합 — 상단 TODO 참고. 확장되면 제한 범위도 넓어진다.)
List<String> restrictQuestionSubjectCodes(List<String> mentorTeachingCodes) {
  final List<String> known = <String>[];
  final Set<String> seen = <String>{};
  for (final String c in mentorTeachingCodes) {
    final String code = c.trim();
    if (code.isEmpty || seen.contains(code)) continue;
    if (subjectLabels.containsKey(code)) {
      seen.add(code);
      known.add(code);
    }
  }
  return known.isNotEmpty ? known : subjectLabels.keys.toList();
}
