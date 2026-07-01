import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/data/mappings/subject_labels.dart';

/// A1: 질문 과목 후보 제한 규칙(순수 함수, DB·네트워크 미접촉).
void main() {
  test('멘토 담당 과목 중 앱이 아는 코드만 후보로 제한(순서 유지·중복 제거)', () {
    final List<String> out = restrictQuestionSubjectCodes(
      <String>['math_calculus', 'english_reading', 'math_calculus'],
    );
    expect(out, <String>['math_calculus', 'english_reading']);
  });

  test('미매핑 코드는 제외한다(영문/기타 남발 방지)', () {
    // 'math'(대분류)·'unknown_x'는 subjectLabels 에 없음 → 제외, 아는 것만 남김.
    final List<String> out = restrictQuestionSubjectCodes(
      <String>['math', 'science_physics', 'unknown_x'],
    );
    expect(out, <String>['science_physics']);
  });

  test('빈 값이면 전체 과목으로 폴백(빈 드롭다운 금지)', () {
    final List<String> out = restrictQuestionSubjectCodes(<String>[]);
    expect(out, subjectLabels.keys.toList());
    expect(out.isNotEmpty, isTrue);
  });

  test('전부 미매핑이면 전체 폴백(웹과 동일: 지정 과목 없으면 전체 허용)', () {
    final List<String> out =
        restrictQuestionSubjectCodes(<String>['math', 'foo', '  ']);
    expect(out, subjectLabels.keys.toList());
  });
}
