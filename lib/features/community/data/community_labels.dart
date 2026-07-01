/// 커뮤니티 카테고리 코드(영문) → 화면 노출용 한글 라벨.
/// ★ 화면에 영문 코드(study/school…)를 노출하지 않는다. 실제 DB 값 기준 매핑.
library;

const Map<String, String> _categoryLabels = <String, String>{
  'study': '학습',
  'school': '내신',
  'free': '자유',
  'college': '대학생활',
  'career': '진로',
};

/// 카테고리 코드 → 한글. 미정/미확정 코드는 '기타'로 폴백(코드 노출 금지).
String communityCategoryLabel(String? code) {
  final String c = code?.trim() ?? '';
  if (c.isEmpty) return '기타';
  return _categoryLabels[c] ?? '기타';
}

/// 게시판 카테고리 필터용 (코드, 라벨) 목록. '전체'는 화면에서 앞에 붙인다.
const List<MapEntry<String, String>> communityCategoryOptions =
    <MapEntry<String, String>>[
  MapEntry<String, String>('study', '학습'),
  MapEntry<String, String>('school', '내신'),
  MapEntry<String, String>('free', '자유'),
  MapEntry<String, String>('college', '대학생활'),
  MapEntry<String, String>('career', '진로'),
];
