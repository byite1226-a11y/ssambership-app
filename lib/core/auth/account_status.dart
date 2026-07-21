import 'package:supabase_flutter/supabase_flutter.dart';

/// 계정 유효 상태(차단 게이팅) — 서버 판정 규칙과 1:1 로 맞춘다(2026-07 스테이징 실측).
///
/// 서버 규칙(정본):
/// - users.status 는 자유 텍스트(CHECK 없음). 서버 RPC 는 lower(status) 로 비교한다.
///   'banned' → 차단, 'suspended' → suspended_until 이 NULL 이거나 미래면 차단
///   (과거면 active 취급), 그 외 값은 전부 active.
/// - users.suspended_until 컬럼은 존재한다(과거 "없음" 주석은 구식 — select 한다).
/// - account_deletion_jobs.state: pending|locked|purging|storage_purged|finalized|
///   auth_soft_deleted|completed|canceled|failed. 이 중 locked~auth_soft_deleted 는
///   서버가 쓰기를 막는 상태(write-block), pending 은 취소 가능(쓰기 미차단),
///   completed 는 탈퇴 완료. canceled/failed 는 없던 일로 본다.
enum AccountStatusKind {
  /// 정상 이용 가능.
  active,

  /// 일시 정지(suspended_until 이 NULL 이거나 미래).
  suspended,

  /// 영구 이용 제한(banned).
  banned,

  /// 탈퇴 요청 접수(취소 가능 창) — 서버는 아직 쓰기를 막지 않는다 → 앱 이용 허용.
  deletionPending,

  /// 탈퇴 처리 진행 중(locked|purging|storage_purged|finalized|auth_soft_deleted)
  /// — 서버가 쓰기를 막는다. 재시도 무의미(비복구 차단).
  deletionLocked,

  /// 탈퇴 완료(completed). 재가입 안내(비복구 차단).
  deleted,

  /// 상태 조회 실패(네트워크/권한) — active 도 banned 도 아닌 별도 상태.
  /// 반드시 '재시도 가능한 차단'으로 다룬다(통과 금지·영구차단 문구 금지).
  fetchFailed,
}

/// 계정 상태 스냅샷.
class AccountState {
  const AccountState({
    required this.kind,
    this.reason,
    this.suspendedUntil,
  });

  final AccountStatusKind kind;

  /// 차단 사유 메모. 없을 수 있음.
  final String? reason;

  /// 정지 해제 예정 시각(users.suspended_until). suspended 일 때만 의미.
  final DateTime? suspendedUntil;

  bool get isActive => kind == AccountStatusKind.active;

  /// 앱 이용(진입) 허용 여부. deletionPending 은 서버가 쓰기를 막지 않으므로 허용.
  bool get allowsAppUse =>
      kind == AccountStatusKind.active ||
      kind == AccountStatusKind.deletionPending;

  /// 재시도로 풀릴 수 있는 상태인지(조회 실패). 차단 화면에서 '다시 시도' 노출 기준.
  bool get isRetryable => kind == AccountStatusKind.fetchFailed;

  bool get isBlocked => !allowsAppUse;

  /// 차단 안내 문구(화면 노출용) — 상태별로 구분된 한국어 안내.
  String get blockedMessage {
    switch (kind) {
      case AccountStatusKind.banned:
        return reason?.trim().isNotEmpty == true
            ? '이용이 제한된 계정이에요.\n$reason'
            : '이용이 제한된 계정이에요.';
      case AccountStatusKind.suspended:
        final DateTime? until = suspendedUntil;
        if (until != null) {
          return '일시 정지된 계정이에요. (해제 예정: ${_fmtDate(until)})';
        }
        return '일시 정지된 계정이에요.';
      case AccountStatusKind.deletionLocked:
        return '탈퇴 처리가 진행 중인 계정이에요.\n처리가 끝나면 새 계정으로 다시 가입할 수 있어요.';
      case AccountStatusKind.deleted:
        return '탈퇴가 완료된 계정이에요.\n다시 이용하려면 새로 가입해 주세요.';
      case AccountStatusKind.fetchFailed:
        return '계정 상태를 확인하지 못했어요.\n네트워크 연결을 확인한 뒤 다시 시도해 주세요.';
      case AccountStatusKind.deletionPending:
      case AccountStatusKind.active:
        return '';
    }
  }

  /// 이용은 가능하지만 알려줄 게 있을 때의 안내(현재는 탈퇴 접수 상태).
  /// 소비하는 UI 가 아직 없으면 무해 — 게이팅은 allowsAppUse 로만 한다.
  String get noticeMessage {
    if (kind == AccountStatusKind.deletionPending) {
      return '탈퇴 요청이 접수된 계정이에요. 취소는 웹에서 할 수 있어요.';
    }
    return '';
  }

  static const AccountState active =
      AccountState(kind: AccountStatusKind.active);
  static const AccountState fetchFailed =
      AccountState(kind: AccountStatusKind.fetchFailed);

  static String _fmtDate(DateTime d) {
    final DateTime local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)}';
  }
}

/// 원시 행 read 포트 — 테스트에서 손코딩 가짜로 주입한다(mocktail 금지).
abstract class AccountStatusGateway {
  /// users 본인 행({'status', 'suspended_until'}). 행 없음 → null. 실패 → throw.
  Future<Map<String, dynamic>?> fetchUserRow(String userId);

  /// account_deletion_jobs 본인 행들([{'state': …}]). 실패 → throw.
  /// (RLS 가 select 를 막는 환경이면 throw 되고, 판정부가 '잡 없음'으로 흡수한다.)
  Future<List<Map<String, dynamic>>> fetchDeletionJobRows(String userId);
}

/// Supabase 실구현(RLS: 본인 행만).
class SupabaseAccountStatusGateway implements AccountStatusGateway {
  SupabaseAccountStatusGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchUserRow(String userId) {
    // suspended_until 은 스테이징 실측으로 존재 확인(2026-07) — 함께 select 한다.
    return _client
        .from('users')
        .select('status, suspended_until')
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDeletionJobRows(String userId) async {
    final List<dynamic> rows = await _client
        .from('account_deletion_jobs')
        .select('state')
        .eq('user_id', userId);
    return rows.cast<Map<String, dynamic>>();
  }
}

/// 계정 유효 상태 판정기.
class AccountStatusReader {
  AccountStatusReader._();

  /// account_deletion_jobs 중 서버가 쓰기를 막는 상태(write-block).
  static const Set<String> _writeBlockedJobStates = <String>{
    'locked',
    'purging',
    'storage_purged',
    'finalized',
    'auth_soft_deleted',
  };

  static Future<AccountState> fetch(SupabaseClient client, String userId) =>
      resolve(SupabaseAccountStatusGateway(client), userId);

  /// 판정 본체(포트 주입 — 단위 테스트 진입점). [now] 는 테스트용 시계 주입.
  static Future<AccountState> resolve(
    AccountStatusGateway gateway,
    String userId, {
    DateTime Function()? now,
  }) async {
    final DateTime nowUtc = (now ?? DateTime.now)().toUtc();

    // 1) users.status — 조회 실패/행 없음은 fetchFailed(재시도 가능 차단, active 아님).
    final Map<String, dynamic>? userRow;
    try {
      userRow = await gateway.fetchUserRow(userId);
    } catch (_) {
      return AccountState.fetchFailed;
    }
    if (userRow == null) return AccountState.fetchFailed;

    // 2) 탈퇴 잡 — RLS 등으로 select 이 막히면 '잡 없음'으로 본다(보수 판정은 status 로).
    List<Map<String, dynamic>> jobRows = const <Map<String, dynamic>>[];
    try {
      jobRows = await gateway.fetchDeletionJobRows(userId);
    } catch (_) {
      jobRows = const <Map<String, dynamic>>[];
    }

    bool jobLocked = false;
    bool jobCompleted = false;
    bool jobPending = false;
    for (final Map<String, dynamic> row in jobRows) {
      final String state =
          (row['state'] as String?)?.trim().toLowerCase() ?? '';
      if (_writeBlockedJobStates.contains(state)) jobLocked = true;
      if (state == 'completed') jobCompleted = true;
      if (state == 'pending') jobPending = true;
      // canceled / failed / 미지 상태는 무시(없던 일로).
    }
    if (jobLocked) {
      return const AccountState(kind: AccountStatusKind.deletionLocked);
    }
    if (jobCompleted) {
      return const AccountState(kind: AccountStatusKind.deleted);
    }

    // 3) status — 서버와 동일하게 lower() 비교. 'banned'/'suspended' 외에는 전부 active.
    final String status =
        (userRow['status'] as String?)?.trim().toLowerCase() ?? '';
    if (status == 'banned') {
      return const AccountState(kind: AccountStatusKind.banned);
    }
    if (status == 'suspended') {
      final DateTime? until = _parseTime(userRow['suspended_until']);
      if (until == null) {
        // 무기한 정지(서버: suspended_until IS NULL → 차단).
        return const AccountState(kind: AccountStatusKind.suspended);
      }
      if (until.toUtc().isAfter(nowUtc)) {
        return AccountState(
          kind: AccountStatusKind.suspended,
          suspendedUntil: until,
        );
      }
      // 정지 기간 경과 → 서버와 동일하게 active 취급(아래로 계속).
    }

    if (jobPending) {
      return const AccountState(kind: AccountStatusKind.deletionPending);
    }
    return AccountState.active;
  }

  static DateTime? _parseTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
