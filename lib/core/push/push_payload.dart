import 'push_types.dart';

/// 딥링크 타깃 종류. ★ S7 은 '어디로 가야 하는지'만 데이터로 정의한다.
///   실제 화면 이동(라우팅)은 S8(notifications/deeplink)이 이 타깃을 소비해 수행한다.
enum PushTargetKind {
  /// 질문방 스레드(질문/답변 화면).
  questionThread,

  /// 커뮤니티 등 일반(추후 확장).
  none,
}

/// 푸시 탭 시 이동할 대상 명세(내부 식별자만 담고 경로 문자열은 만들지 않는다).
/// ★ 사용자에게 thread id 등 내부 값은 노출하지 않는다(S8 이 라우팅에만 사용).
class PushTarget {
  const PushTarget({required this.kind, this.threadId});

  final PushTargetKind kind;

  /// questionThread 일 때 대상 스레드 id(딥링크용, 화면 비노출).
  final String? threadId;

  static const PushTarget none = PushTarget(kind: PushTargetKind.none);

  factory PushTarget.thread(String threadId) =>
      PushTarget(kind: PushTargetKind.questionThread, threadId: threadId);

  /// FCM data 맵 → 타깃. thread_id 가 있으면 스레드 타깃.
  factory PushTarget.fromData(Map<String, dynamic> data) {
    final Object? tid = data['thread_id'];
    if (tid is String && tid.isNotEmpty) {
      return PushTarget.thread(tid);
    }
    return PushTarget.none;
  }

  Map<String, dynamic> toData() => <String, dynamic>{
        if (threadId != null) 'thread_id': threadId,
      };
}

/// 푸시 한 건의 payload(표시 문구 + 타깃 + 원본 data). 실제 전송은 sender 포트가 한다.
class PushPayload {
  const PushPayload({
    required this.type,
    required this.title,
    required this.body,
    required this.target,
    this.data = const <String, dynamic>{},
  });

  final PushType type;
  final String title;
  final String body;
  final PushTarget target;

  /// FCM data 페이로드(딥링크·타입 등). title/body 는 notification 파트.
  final Map<String, dynamic> data;

  /// 서버/FCM 로 보낼 data 맵(type + 타깃 + 부가).
  Map<String, dynamic> toData() => <String, dynamic>{
        'type': type.code,
        ...target.toData(),
        ...data,
      };

  /// 수신된 원격 메시지(data + notification) → payload 복원(수신 핸들러용, 인수인계).
  factory PushPayload.fromRemote(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    return PushPayload(
      type: PushType.fromCode(data['type'] as String?),
      title: title ?? '',
      body: body ?? '',
      target: PushTarget.fromData(data),
      data: data,
    );
  }
}

/// 발송 트리거가 이벤트 → payload 를 만드는 순수 빌더(테스트 대상).
/// ★ title/body 는 한글 사용자 문구. data 에만 thread_id(비노출 딥링크)를 담는다.
class PushPayloadBuilder {
  PushPayloadBuilder._();

  /// 멘토 답변 등록 → 학생에게.
  static PushPayload questionAnswered({
    required String threadId,
    String? threadTitle,
  }) {
    final String t = threadTitle?.trim() ?? '';
    return PushPayload(
      type: PushType.questionAnswered,
      title: '답변이 도착했어요',
      body: t.isNotEmpty ? '‘$t’에 멘토가 답변을 남겼어요.' : '멘토가 답변을 남겼어요.',
      target: PushTarget.thread(threadId),
    );
  }

  /// 새 질문/메시지 → 상대에게(멘토 또는 학생).
  static PushPayload questionMessageReceived({
    required String threadId,
    String? threadTitle,
    bool toMentor = true,
  }) {
    final String t = threadTitle?.trim() ?? '';
    final String who = toMentor ? '학생' : '멘토';
    return PushPayload(
      type: PushType.questionMessageReceived,
      title: toMentor ? '새 질문이 도착했어요' : '새 메시지가 도착했어요',
      body: t.isNotEmpty ? '‘$t’에 $who의 새 메시지가 있어요.' : '$who의 새 메시지가 있어요.',
      target: PushTarget.thread(threadId),
    );
  }

  /// 연결노트 추가 → 상대에게. (방 단위 이벤트 — 스레드 타깃 아님)
  static PushPayload connectionNoteAdded() {
    return const PushPayload(
      type: PushType.connectionNoteAdded,
      title: '연결노트가 업데이트됐어요',
      body: '상대가 연결노트를 남겼어요.',
      target: PushTarget.none,
    );
  }
}
