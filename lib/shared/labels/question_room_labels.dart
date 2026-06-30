import '../../features/question_room/data/models/connection_note.dart';
import '../../features/question_room/data/models/question_thread.dart';

/// 질문방 코드값(enum) → 화면 노출용 한글 라벨.
///
/// ★ 화면에는 영문 status/role 코드를 절대 그대로 노출하지 않는다.
///   코드는 내부값, 사용자는 한글만 본다.
class QuestionRoomLabels {
  QuestionRoomLabels._();

  /// 스레드 상태 한글 라벨.
  /// pending/answered/confirmed 는 확정 라벨.
  /// open/closed/archived 는 우선 잠정(기획 확정 시 교체).
  static String threadStatus(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.pending:
        return '답변 대기';
      case ThreadStatus.answered:
        return '답변 완료';
      case ThreadStatus.confirmed:
        return '확인 완료';
      case ThreadStatus.open:
        return '진행 중'; // 잠정
      case ThreadStatus.closed:
        return '종료'; // 잠정
      case ThreadStatus.archived:
        return '보관됨'; // 잠정
      case ThreadStatus.unknown:
        return '상태 미상';
    }
  }

  /// 학습 숙련 상태 한글 라벨.
  static String masteryStatus(MasteryStatus status) {
    switch (status) {
      case MasteryStatus.unknown:
        return '미정';
      case MasteryStatus.wrong:
        return '오답';
      case MasteryStatus.review:
        return '복습 필요';
      case MasteryStatus.mastered:
        return '완전 학습';
    }
  }

  /// 노트 작성자 역할 한글 라벨.
  static String noteAuthorRole(NoteAuthorRole role) {
    switch (role) {
      case NoteAuthorRole.student:
        return '학생';
      case NoteAuthorRole.mentor:
        return '멘토';
      case NoteAuthorRole.unknown:
        return '작성자 미상';
    }
  }
}
