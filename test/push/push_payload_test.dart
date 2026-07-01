import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/push/push_payload.dart';
import 'package:ssambership_app/core/push/push_types.dart';

/// payload/타깃 명세(순수). 실제 전송 없이 구조·문구·딥링크 타깃만 검증.
void main() {
  group('PushPayloadBuilder.questionAnswered', () {
    test('타입·타깃·문구·data 구성', () {
      final PushPayload p = PushPayloadBuilder.questionAnswered(
        threadId: 'th-1',
        threadTitle: '미분 질문',
      );
      expect(p.type, PushType.questionAnswered);
      expect(p.target.kind, PushTargetKind.questionThread);
      expect(p.target.threadId, 'th-1'); // 딥링크 타깃(데이터)
      expect(p.title, '답변이 도착했어요');
      expect(p.body.contains('미분 질문'), isTrue);
      // data 에 type 코드 + thread_id(딥링크). 화면 문구엔 내부 id 없음.
      expect(p.toData()['type'], 'question_answered');
      expect(p.toData()['thread_id'], 'th-1');
      expect(p.title.contains('th-1'), isFalse);
      expect(p.body.contains('th-1'), isFalse);
    });

    test('제목 없으면 일반 문구로 폴백', () {
      final PushPayload p = PushPayloadBuilder.questionAnswered(threadId: 'th-1');
      expect(p.body, '멘토가 답변을 남겼어요.');
    });
  });

  group('questionMessageReceived 방향별 문구', () {
    test('멘토에게(toMentor=true)', () {
      final PushPayload p = PushPayloadBuilder.questionMessageReceived(
          threadId: 't', toMentor: true);
      expect(p.title, '새 질문이 도착했어요');
      expect(p.type, PushType.questionMessageReceived);
    });
    test('학생에게(toMentor=false)', () {
      final PushPayload p = PushPayloadBuilder.questionMessageReceived(
          threadId: 't', toMentor: false);
      expect(p.title, '새 메시지가 도착했어요');
    });
  });

  group('PushTarget.fromData', () {
    test('thread_id 있으면 questionThread', () {
      final PushTarget t = PushTarget.fromData(<String, dynamic>{'thread_id': 'x'});
      expect(t.kind, PushTargetKind.questionThread);
      expect(t.threadId, 'x');
    });
    test('없으면 none', () {
      expect(PushTarget.fromData(<String, dynamic>{}).kind, PushTargetKind.none);
    });
  });

  test('PushPayload.fromRemote: data → type/타깃 복원', () {
    final PushPayload p = PushPayload.fromRemote(
      <String, dynamic>{'type': 'question_answered', 'thread_id': 'th-9'},
      title: '답변',
      body: '내용',
    );
    expect(p.type, PushType.questionAnswered);
    expect(p.target.threadId, 'th-9');
  });

  test('PushType code ↔ fromCode 왕복, 미지 코드는 unknown', () {
    for (final PushType t in PushType.values) {
      expect(PushType.fromCode(t.code), t);
    }
    expect(PushType.fromCode('made_up'), PushType.unknown);
  });
}
