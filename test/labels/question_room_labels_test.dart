import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/models/connection_note.dart';
import 'package:ssambership_app/features/question_room/data/models/question_thread.dart';
import 'package:ssambership_app/shared/labels/question_room_labels.dart';

/// 순수 함수 테스트 — 상태 코드(영문)가 화면 노출용 한글 라벨로 매핑되는지.
/// ★ 웹 기준 매핑: pending=답변 대기, answered=진행 중, confirmed=답변 완료.
void main() {
  group('QuestionRoomLabels.threadStatus (웹 기준 매핑)', () {
    test('pending → "답변 대기"', () {
      expect(QuestionRoomLabels.threadStatus(ThreadStatus.pending), '답변 대기');
    });

    test('answered → "진행 중" (답변 완료 아님)', () {
      expect(QuestionRoomLabels.threadStatus(ThreadStatus.answered), '진행 중');
    });

    test('confirmed → "답변 완료"', () {
      expect(QuestionRoomLabels.threadStatus(ThreadStatus.confirmed), '답변 완료');
    });

    test('open 은 내부 기본값으로 answered 와 동일 취급("진행 중")', () {
      expect(QuestionRoomLabels.threadStatus(ThreadStatus.open), '진행 중');
    });

    test('모든 상태가 영문 코드를 그대로 노출하지 않는다', () {
      for (final ThreadStatus s in ThreadStatus.values) {
        final String label = QuestionRoomLabels.threadStatus(s);
        // 영문 enum 이름이 라벨에 새어 나오면 안 된다.
        expect(label.contains(s.name), isFalse,
            reason: '$s 라벨에 영문 코드(${s.name})가 노출됨: "$label"');
        expect(RegExp(r'[a-zA-Z]').hasMatch(label), isFalse,
            reason: '$s 라벨에 영문자가 포함됨: "$label"');
      }
    });
  });

  group('QuestionRoomLabels.noteAuthorRole', () {
    test('student → "학생", mentor → "멘토"', () {
      expect(QuestionRoomLabels.noteAuthorRole(NoteAuthorRole.student), '학생');
      expect(QuestionRoomLabels.noteAuthorRole(NoteAuthorRole.mentor), '멘토');
    });
  });

  group('QuestionRoomLabels.masteryStatus', () {
    test('코드별 한글 라벨', () {
      expect(QuestionRoomLabels.masteryStatus(MasteryStatus.wrong), '오답');
      expect(QuestionRoomLabels.masteryStatus(MasteryStatus.review), '복습 필요');
      expect(QuestionRoomLabels.masteryStatus(MasteryStatus.mastered), '완전 학습');
      expect(QuestionRoomLabels.masteryStatus(MasteryStatus.unknown), '미정');
    });
  });
}
