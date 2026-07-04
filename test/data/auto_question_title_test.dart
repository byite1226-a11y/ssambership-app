import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/models/question_thread.dart';

/// 제목 미입력 시 자동 제목 규칙(순수 함수) — 방의 질문 순번(1-based).
void main() {
  test('autoQuestionTitle: N = 기존 질문 수 + 1', () {
    expect(autoQuestionTitle(0), '1번 질문'); // 방의 첫 질문
    expect(autoQuestionTitle(1), '2번 질문');
    expect(autoQuestionTitle(2), '3번 질문');
    expect(autoQuestionTitle(9), '10번 질문');
  });
}
