import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/auth/account_status.dart';

/// P2-22: 계정 유효 상태 판정 — 서버 규칙(lower(status)·suspended_until·탈퇴 잡)과 1:1.
/// 네트워크 미접촉: 손코딩 가짜 게이트웨이 주입(mocktail 금지 관례).
class _FakeGateway implements AccountStatusGateway {
  _FakeGateway({
    this.userRow,
    this.jobRows = const <Map<String, dynamic>>[],
    this.userThrows = false,
    this.jobThrows = false,
  });

  final Map<String, dynamic>? userRow;
  final List<Map<String, dynamic>> jobRows;
  final bool userThrows;
  final bool jobThrows;

  @override
  Future<Map<String, dynamic>?> fetchUserRow(String userId) async {
    if (userThrows) throw Exception('network down');
    return userRow;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDeletionJobRows(String userId) async {
    if (jobThrows) throw Exception('RLS: permission denied');
    return jobRows;
  }
}

void main() {
  final DateTime now = DateTime.utc(2026, 7, 21, 12);
  DateTime clock() => now;

  Future<AccountState> resolve(_FakeGateway g) =>
      AccountStatusReader.resolve(g, 'u1', now: clock);

  group('users.status 판정(서버와 동일: lower 비교, 그 외 값은 active)', () {
    test('active → active(이용 가능)', () async {
      final AccountState s = await resolve(
          _FakeGateway(userRow: <String, dynamic>{'status': 'active'}));
      expect(s.kind, AccountStatusKind.active);
      expect(s.allowsAppUse, isTrue);
      expect(s.isBlocked, isFalse);
    });

    test('정본 밖 status 값(free text)은 서버와 동일하게 active 취급', () async {
      final AccountState s = await resolve(
          _FakeGateway(userRow: <String, dynamic>{'status': 'whatever'}));
      expect(s.kind, AccountStatusKind.active);
    });

    test('banned → banned(영구 차단·재시도 아님)', () async {
      final AccountState s = await resolve(
          _FakeGateway(userRow: <String, dynamic>{'status': 'banned'}));
      expect(s.kind, AccountStatusKind.banned);
      expect(s.isBlocked, isTrue);
      expect(s.isRetryable, isFalse);
      expect(s.blockedMessage, contains('제한된 계정'));
    });

    test('대소문자 무시: BANNED 도 banned(서버 lower(status) 비교와 동일)', () async {
      final AccountState s = await resolve(
          _FakeGateway(userRow: <String, dynamic>{'status': ' BANNED '}));
      expect(s.kind, AccountStatusKind.banned);
    });

    test('suspended + suspended_until 미래 → suspended(해제일 안내 포함)', () async {
      final AccountState s =
          await resolve(_FakeGateway(userRow: <String, dynamic>{
        'status': 'suspended',
        'suspended_until': '2026-08-01T00:00:00Z',
      }));
      expect(s.kind, AccountStatusKind.suspended);
      expect(s.suspendedUntil, isNotNull);
      expect(s.isBlocked, isTrue);
      expect(s.blockedMessage, contains('일시 정지'));
      expect(s.blockedMessage, contains('해제 예정'));
    });

    test('suspended + suspended_until 과거 → 서버와 동일하게 active 취급', () async {
      final AccountState s =
          await resolve(_FakeGateway(userRow: <String, dynamic>{
        'status': 'suspended',
        'suspended_until': '2026-01-01T00:00:00Z',
      }));
      expect(s.kind, AccountStatusKind.active);
      expect(s.allowsAppUse, isTrue);
    });

    test('suspended + suspended_until NULL → 무기한 정지(차단)', () async {
      final AccountState s =
          await resolve(_FakeGateway(userRow: <String, dynamic>{
        'status': 'suspended',
        'suspended_until': null,
      }));
      expect(s.kind, AccountStatusKind.suspended);
      expect(s.isBlocked, isTrue);
    });
  });

  group('account_deletion_jobs 판정', () {
    Map<String, dynamic> activeUser() => <String, dynamic>{'status': 'active'};

    test('pending → deletionPending(취소 창: 이용 허용 + 안내 문구)', () async {
      final AccountState s = await resolve(_FakeGateway(
        userRow: activeUser(),
        jobRows: <Map<String, dynamic>>[
          <String, dynamic>{'state': 'pending'},
        ],
      ));
      expect(s.kind, AccountStatusKind.deletionPending);
      expect(s.allowsAppUse, isTrue); // 서버가 쓰기를 막지 않는 구간
      expect(s.isBlocked, isFalse);
      expect(s.noticeMessage, contains('탈퇴 요청'));
    });

    test('locked/purging 등 write-block 상태 → deletionLocked(비복구 차단)', () async {
      for (final String state in <String>[
        'locked',
        'purging',
        'storage_purged',
        'finalized',
        'auth_soft_deleted',
      ]) {
        final AccountState s = await resolve(_FakeGateway(
          userRow: activeUser(),
          jobRows: <Map<String, dynamic>>[
            <String, dynamic>{'state': state},
          ],
        ));
        expect(s.kind, AccountStatusKind.deletionLocked, reason: state);
        expect(s.isBlocked, isTrue, reason: state);
        expect(s.isRetryable, isFalse, reason: state); // 자동/수동 재시도 무의미
        expect(s.blockedMessage, contains('탈퇴 처리가 진행 중'), reason: state);
      }
    });

    test('completed → deleted(재가입 안내·비복구)', () async {
      final AccountState s = await resolve(_FakeGateway(
        userRow: activeUser(),
        jobRows: <Map<String, dynamic>>[
          <String, dynamic>{'state': 'completed'},
        ],
      ));
      expect(s.kind, AccountStatusKind.deleted);
      expect(s.isRetryable, isFalse);
      expect(s.blockedMessage, contains('새로 가입'));
    });

    test('canceled/failed 잡은 없던 일로(active)', () async {
      final AccountState s = await resolve(_FakeGateway(
        userRow: activeUser(),
        jobRows: <Map<String, dynamic>>[
          <String, dynamic>{'state': 'canceled'},
          <String, dynamic>{'state': 'failed'},
        ],
      ));
      expect(s.kind, AccountStatusKind.active);
    });

    test('잡이 여러 개면 write-block > completed > pending 우선', () async {
      final AccountState s = await resolve(_FakeGateway(
        userRow: activeUser(),
        jobRows: <Map<String, dynamic>>[
          <String, dynamic>{'state': 'canceled'},
          <String, dynamic>{'state': 'pending'},
          <String, dynamic>{'state': 'locked'},
        ],
      ));
      expect(s.kind, AccountStatusKind.deletionLocked);
    });

    test('잡 select 이 RLS 등으로 throw → 잡 없음으로 흡수(status 로만 판정)', () async {
      final AccountState s = await resolve(_FakeGateway(
        userRow: activeUser(),
        jobThrows: true,
      ));
      expect(s.kind, AccountStatusKind.active);
    });

    test('banned + pending 잡 → banned 이 우선(차단 유지)', () async {
      final AccountState s = await resolve(_FakeGateway(
        userRow: <String, dynamic>{'status': 'banned'},
        jobRows: <Map<String, dynamic>>[
          <String, dynamic>{'state': 'pending'},
        ],
      ));
      expect(s.kind, AccountStatusKind.banned);
    });
  });

  group('조회 실패 → fetchFailed(재시도 가능 차단 — active 도 banned 도 아님)', () {
    test('users read throw → fetchFailed', () async {
      final AccountState s = await resolve(_FakeGateway(userThrows: true));
      expect(s.kind, AccountStatusKind.fetchFailed);
      expect(s.allowsAppUse, isFalse); // 통과 금지(fail-closed)
      expect(s.isRetryable, isTrue); // 그러나 재시도 가능(영구 차단 문구 금지)
      expect(s.blockedMessage, contains('다시 시도'));
      expect(s.blockedMessage, isNot(contains('제한된 계정')));
    });

    test('users 행 없음 → fetchFailed(통과 금지·재시도 가능)', () async {
      final AccountState s = await resolve(_FakeGateway(userRow: null));
      expect(s.kind, AccountStatusKind.fetchFailed);
      expect(s.isRetryable, isTrue);
    });
  });
}
