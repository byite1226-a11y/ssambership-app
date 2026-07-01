import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/data/mappings/subject_labels.dart';

/// A1: 질문 과목 후보 제한 규칙(순수 함수, DB·네트워크 미접촉).
///
/// ★ 실측 정합: DB `mentor_profiles.teaching_subjects` 는 한글 라벨(수학·영어…)로 저장된다.
///   과거 구현은 앱 전용 영문코드(math_common…)로만 매칭해 한글 라벨을 전부 탈락시켜
///   '항상 전체 폴백'되는 버그가 있었다. 아래는 정본(코드/라벨) 어휘로 실제 제한됨을 검증.
void main() {
  test('멘토 담당과목이 한글 라벨(수학·영어)이면 그 과목만 후보로 정규화(math·english)', () {
    // 로컬 실데이터: mentor 5b6dc968… teaching_subjects = {수학,영어}
    final List<String> out = restrictQuestionSubjectCodes(<String>['수학', '영어']);
    expect(out, <String>['math', 'english']);
    // 전체 폴백이 아님을 명시(핵심: 화면에 전체가 뜨면 안 됨)
    expect(out.length, lessThan(subjectLabels.length));
    expect(subjectLabel(out[0]), '수학');
    expect(subjectLabel(out[1]), '영어');
  });

  test('멘토 담당과목이 코드(math·math_calculus)여도 그대로 제한', () {
    final List<String> out =
        restrictQuestionSubjectCodes(<String>['math', 'math_calculus']);
    expect(out, <String>['math', 'math_calculus']);
    expect(out.length, lessThan(subjectLabels.length));
  });

  test('한글 라벨과 코드가 같은 과목이면 중복 제거(수학=math)', () {
    final List<String> out =
        restrictQuestionSubjectCodes(<String>['수학', 'math', '수학']);
    expect(out, <String>['math']);
  });

  test('정규화 안 되는 자유 라벨(코딩)은 버리지 않고 후보 유지', () {
    // 로컬 실데이터: {수학,코딩} — 코딩은 정본에 없지만 멘토 실제 과목이므로 남긴다.
    final List<String> out = restrictQuestionSubjectCodes(<String>['수학', '코딩']);
    expect(out, <String>['math', '코딩']);
    expect(subjectLabel('코딩'), '코딩'); // 한글 자유 라벨은 그대로 표시
    expect(out.length, lessThan(subjectLabels.length));
  });

  test('빈 값이면 전체 과목으로 폴백(빈 드롭다운 금지)', () {
    final List<String> out = restrictQuestionSubjectCodes(<String>[]);
    expect(out, subjectLabels.keys.toList());
    expect(out.isNotEmpty, isTrue);
  });

  test('공백만 있으면 전체 폴백', () {
    final List<String> out =
        restrictQuestionSubjectCodes(<String>['  ', '\t']);
    expect(out, subjectLabels.keys.toList());
  });

  test('subjectLabel: 정본 코드는 한글 라벨, 영문 미매핑은 기타, 빈값은 미분류', () {
    expect(subjectLabel('math'), '수학'); // 과거엔 '기타'로 나오던 버그
    expect(subjectLabel('korean'), '국어');
    expect(subjectLabel('english'), '영어');
    expect(subjectLabel('unknown_ascii_code'), '기타');
    expect(subjectLabel(null), '미분류');
    expect(subjectLabel('   '), '미분류');
  });
}
