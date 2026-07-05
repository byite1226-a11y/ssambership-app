import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/individual_question/data/models/individual_question_models.dart';

void main() {
  group('상태 파싱(웹 070 CHECK 값 미러)', () {
    test('전체 상태값 왕복', () {
      const Map<String, IndividualQuestionStatus> cases =
          <String, IndividualQuestionStatus>{
        'escrowed': IndividualQuestionStatus.escrowed,
        'assigned': IndividualQuestionStatus.assigned,
        'open': IndividualQuestionStatus.open,
        'claimed': IndividualQuestionStatus.claimed,
        'answered': IndividualQuestionStatus.answered,
        'released': IndividualQuestionStatus.released,
        'expired': IndividualQuestionStatus.expired,
        'refunded': IndividualQuestionStatus.refunded,
        'canceled': IndividualQuestionStatus.canceled,
      };
      cases.forEach((String db, IndividualQuestionStatus expected) {
        expect(iqStatusFromDb(db), expected, reason: db);
        expect(iqStatusFromDb(db.toUpperCase()), expected, reason: db);
      });
      expect(iqStatusFromDb(null), IndividualQuestionStatus.unknown);
      expect(iqStatusFromDb('weird'), IndividualQuestionStatus.unknown);
    });

    test('상태 한글 라벨(answered/released 는 앱 전용 새 용어)', () {
      expect(iqStatusLabel(IndividualQuestionStatus.escrowed), '예치중');
      expect(iqStatusLabel(IndividualQuestionStatus.open), '공개중');
      expect(iqStatusLabel(IndividualQuestionStatus.assigned), '답변중');
      expect(iqStatusLabel(IndividualQuestionStatus.claimed), '답변중');
      expect(iqStatusLabel(IndividualQuestionStatus.answered), '답변 도착');
      expect(iqStatusLabel(IndividualQuestionStatus.released), '답변완료');
      expect(iqStatusLabel(IndividualQuestionStatus.refunded), '환불');
      expect(iqStatusLabel(IndividualQuestionStatus.expired), '만료');
      expect(iqStatusLabel(IndividualQuestionStatus.canceled), '취소');
      expect(iqStatusLabel(IndividualQuestionStatus.unknown), '진행 중');
    });

    test('유형 라벨: open=공개형, direct=지정형', () {
      expect(iqTypeLabel(iqTypeFromDb('open')), '공개형');
      expect(iqTypeLabel(iqTypeFromDb('direct')), '지정형');
    });
  });

  group('액션 규칙(웹 actions 가드 미러)', () {
    test('학생 해결 완료(release)는 answered 에서만', () {
      for (final IndividualQuestionStatus s in IndividualQuestionStatus.values) {
        expect(iqCanStudentRelease(s), s == IndividualQuestionStatus.answered,
            reason: '$s');
      }
    });

    test('학생 취소(환불)는 답변 대기 상태에서만 — answered 이후 불가', () {
      const Set<IndividualQuestionStatus> allowed =
          <IndividualQuestionStatus>{
        IndividualQuestionStatus.escrowed,
        IndividualQuestionStatus.open,
        IndividualQuestionStatus.assigned,
        IndividualQuestionStatus.claimed,
      };
      for (final IndividualQuestionStatus s in IndividualQuestionStatus.values) {
        expect(iqCanStudentRefund(s), allowed.contains(s), reason: '$s');
      }
      expect(iqCanStudentRefund(IndividualQuestionStatus.answered), false);
      expect(iqCanStudentRefund(IndividualQuestionStatus.released), false);
    });

    test('멘토 답변은 claimed/assigned 에서만(RPC 가드 동일)', () {
      for (final IndividualQuestionStatus s in IndividualQuestionStatus.values) {
        expect(
          iqCanMentorAnswer(s),
          s == IndividualQuestionStatus.claimed ||
              s == IndividualQuestionStatus.assigned,
          reason: '$s',
        );
      }
    });
  });

  group('표시 포맷', () {
    test('캐시 표기: cents ÷100 + 천 단위 콤마(웹 미러)', () {
      expect(formatIqCash(500000), '5,000캐시');
      expect(formatIqCash(100), '1캐시');
      expect(formatIqCash(12345600), '123,456캐시');
      expect(formatIqCash(0), '0캐시');
    });

    test('마감 남은시간: 대기 상태에서만, 웹 문구 미러', () {
      final DateTime now = DateTime(2026, 7, 2, 12);
      DateTime Function() at(DateTime t) => () => t;

      // 대기 아님 → null.
      expect(
        formatIqExpiryRemaining(
          now.add(const Duration(hours: 5)),
          IndividualQuestionStatus.answered,
          now: at(now),
        ),
        isNull,
      );
      // 마감 없음 → null.
      expect(
        formatIqExpiryRemaining(null, IndividualQuestionStatus.open,
            now: at(now)),
        isNull,
      );
      expect(
        formatIqExpiryRemaining(
          now.subtract(const Duration(minutes: 1)),
          IndividualQuestionStatus.open,
          now: at(now),
        ),
        '마감 지남',
      );
      expect(
        formatIqExpiryRemaining(
          now.add(const Duration(minutes: 30)),
          IndividualQuestionStatus.claimed,
          now: at(now),
        ),
        '곧 마감',
      );
      expect(
        formatIqExpiryRemaining(
          now.add(const Duration(hours: 5)),
          IndividualQuestionStatus.open,
          now: at(now),
        ),
        '5시간 후 마감',
      );
      expect(
        formatIqExpiryRemaining(
          now.add(const Duration(days: 2, hours: 1)),
          IndividualQuestionStatus.assigned,
          now: at(now),
        ),
        '2일 후 마감',
      );
    });
  });

  group('실패 메시지 매핑(코드 비노출)', () {
    test('주요 코드 → 한글 안내', () {
      expect(iqFailureMessage(Exception('CASH_INSUFFICIENT')),
          contains('캐시가 부족'));
      expect(iqFailureMessage(Exception('MENTOR_PRICE_NOT_SET')),
          contains('가격을 설정하지 않았'));
      expect(iqFailureMessage(Exception('NOT_QUESTION_OWNER')),
          contains('권한이 없어요'));
      expect(
          iqFailureMessage(Exception(
              'INDIVIDUAL_QUESTION_CLAIM_FAILED:already_claimed:x')),
          contains('먼저 수락'));
      expect(iqFailureMessage(Exception('already_released')),
          contains('정산이 완료'));
      expect(iqFailureMessage(Exception('what_is_this')),
          contains('다시 시도'));
    });
  });

  group('fromMap 파싱', () {
    test('IndividualQuestion: 필드 + 담당 멘토(claimed 우선)', () {
      final IndividualQuestion q =
          IndividualQuestion.fromMap(<String, dynamic>{
        'id': 'q1',
        'student_id': 's1',
        'question_type': 'open',
        'status': 'claimed',
        'title': ' 미분 질문 ',
        'body': '본문',
        'price_cents': 500000,
        'designated_mentor_id': null,
        'claimed_mentor_id': 'm2',
        'expires_at': '2026-07-04T00:00:00Z',
        'created_at': '2026-07-02T00:00:00Z',
      });
      expect(q.id, 'q1');
      expect(q.type, IndividualQuestionType.open);
      expect(q.status, IndividualQuestionStatus.claimed);
      expect(q.title, '미분 질문');
      expect(q.priceCents, 500000);
      expect(q.mentorId, 'm2');
      expect(q.expiresAt, isNotNull);

      final IndividualQuestion direct =
          IndividualQuestion.fromMap(<String, dynamic>{
        'id': 'q2',
        'student_id': 's1',
        'question_type': 'direct',
        'status': 'assigned',
        'title': 't',
        'body': 'b',
        'price_cents': 300000,
        'designated_mentor_id': 'm1',
        'claimed_mentor_id': null,
      });
      expect(direct.mentorId, 'm1');
    });

    test('IqEscrowResult: 070 결과 타입', () {
      final IqEscrowResult r = IqEscrowResult.fromMap(<String, dynamic>{
        'ok': true,
        'code': 'released',
        'message': 'individual question payout released',
        'question_id': 'q1',
        'status': 'released',
        'ledger_id': 'l1',
        'wallet_balance_cents': 120000,
      });
      expect(r.ok, true);
      expect(r.code, 'released');
      expect(r.status, IndividualQuestionStatus.released);
      expect(r.walletBalanceCents, 120000);
    });

    test('OpenIndividualQuestion: 위생 필드만', () {
      final OpenIndividualQuestion o =
          OpenIndividualQuestion.fromMap(<String, dynamic>{
        'id': 'q1',
        'title': '적분',
        'price_cents': 700000,
        'subject': 'math',
        'expires_at': '2026-07-04T00:00:00Z',
      });
      expect(o.title, '적분');
      expect(o.priceCents, 700000);
    });
  });
}
