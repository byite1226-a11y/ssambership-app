/// 푸시 알림 타입·권한 상태 정의. ★ DB `notifications.type` 값과 정렬(같은 taxonomy).
///   화면에는 영문 코드/내부 id 를 노출하지 않는다(라벨/문구는 payload 빌더가 한글로).
library;

/// 푸시로 보낼 이벤트 타입(질문/답변 중심 + 확장 여지). 코드 = DB notifications.type.
enum PushType {
  /// 멘토가 답변을 등록 → 학생에게.
  questionAnswered,

  /// 새 질문/메시지 도착 → 상대에게(멘토/학생).
  questionMessageReceived,

  /// 연결노트 추가 → 상대에게.
  connectionNoteAdded,

  /// 알 수 없는(미래) 타입 안전 폴백.
  unknown;

  /// DB/서버 코드.
  String get code {
    switch (this) {
      case PushType.questionAnswered:
        return 'question_answered';
      case PushType.questionMessageReceived:
        return 'question_message_received';
      case PushType.connectionNoteAdded:
        return 'connection_note_added';
      case PushType.unknown:
        return 'unknown';
    }
  }

  static PushType fromCode(String? code) {
    switch (code?.trim()) {
      case 'question_answered':
        return PushType.questionAnswered;
      case 'question_message_received':
        return PushType.questionMessageReceived;
      case 'connection_note_added':
        return PushType.connectionNoteAdded;
      default:
        return PushType.unknown;
    }
  }
}

/// 알림 권한 상태(플랫폼 무관 추상). 실제 OS 권한 매핑은 포트 구현(인수인계).
enum PushPermissionStatus {
  /// 아직 물어보지 않음.
  notDetermined,

  /// 허용됨.
  granted,

  /// 거부됨(마이페이지에서 재요청 유도 가능).
  denied;

  bool get isGranted => this == PushPermissionStatus.granted;
}
