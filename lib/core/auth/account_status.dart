import 'package:supabase_flutter/supabase_flutter.dart';

/// 계정 상태(차단 게이팅). public.users.status 를 읽어 통과/차단을 판정한다.
///
/// 규칙: 'active' 만 통과. 'banned'/'suspended' 는 차단 사유를 담는다.
/// 읽기 실패/행 없음 → unknown(보수적으로 통과시키지 않음 — 진입 가드에서 차단 처리).
enum AccountStatusKind { active, banned, suspended, unknown }

/// 계정 상태 스냅샷.
class AccountState {
  const AccountState({
    required this.kind,
    this.reason,
    this.suspendedUntil,
  });

  final AccountStatusKind kind;

  /// 차단 사유 메모(users.status_reason). 없을 수 있음.
  final String? reason;

  /// 정지 해제 예정 시각(users.suspended_until). suspended 일 때만 의미.
  final DateTime? suspendedUntil;

  bool get isActive => kind == AccountStatusKind.active;

  bool get isBlocked =>
      kind == AccountStatusKind.banned || kind == AccountStatusKind.suspended;

  /// 차단 안내 문구(화면 노출용).
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
      case AccountStatusKind.unknown:
        return '계정 상태를 확인할 수 없어요. 잠시 후 다시 시도해 주세요.';
      case AccountStatusKind.active:
        return '';
    }
  }

  static const AccountState active = AccountState(kind: AccountStatusKind.active);
  static const AccountState unknown =
      AccountState(kind: AccountStatusKind.unknown);

  static String _fmtDate(DateTime d) {
    final DateTime local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)}';
  }
}

/// users.status 읽기 전용 리더(RLS: 본인 행만).
class AccountStatusReader {
  AccountStatusReader._();

  static Future<AccountState> fetch(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      final Map<String, dynamic>? row = await client
          .from('users')
          .select('status, status_reason, suspended_until')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return AccountState.unknown;

      final String status = (row['status'] as String?)?.trim() ?? '';
      final String? reason = row['status_reason'] as String?;
      final String? untilRaw = row['suspended_until'] as String?;
      final DateTime? until =
          untilRaw == null ? null : DateTime.tryParse(untilRaw);

      switch (status) {
        case 'active':
          return AccountState.active;
        case 'banned':
          return AccountState(kind: AccountStatusKind.banned, reason: reason);
        case 'suspended':
          return AccountState(
            kind: AccountStatusKind.suspended,
            reason: reason,
            suspendedUntil: until,
          );
        default:
          // 알 수 없는 상태값은 통과시키지 않는다('active'만 통과).
          return AccountState.unknown;
      }
    } catch (_) {
      return AccountState.unknown;
    }
  }
}
