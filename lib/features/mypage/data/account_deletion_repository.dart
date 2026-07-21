import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';

/// 계정 탈퇴(P1-10) — 서버 RPC 계약(스냅샷 §4.2/§4.6)에 1:1.
///
/// ★ 스테이징 실측(2026-07-21): `account_deletion_request`/`account_deletion_cancel`
///   은 현재 **service_role 전용**(authenticated EXECUTE 없음) → 앱 직접 호출은
///   42501 로 거부된다. 이 레포는 계약 그대로 구현·테스트해 두고(grant 즉시 활성),
///   권한 거부는 [AccountDeletionUnavailable] 로 구분해 화면이 웹 폴백을 안내한다.
///   상태: WAITING_SERVER_API (grant 요청은 APP_V16_MIN_VERSION_SERVER_REQUIREMENT.md).
/// ★ 실제 요청은 반드시 `p_dry_run=false` 명시 — 서버 기본값(true)에 의존하지 않는다.

/// 탈퇴 요청 결과(RPC 반환 {ok, existing, job_id, state}).
class DeletionRequestResult {
  const DeletionRequestResult({
    required this.existing,
    required this.jobId,
    required this.state,
  });

  /// true = 이미 접수된 job 이 있어 그 상태를 돌려줌(멱등 — 이중 탭/재요청 안전).
  final bool existing;
  final String jobId;

  /// pending|locked|purging|storage_purged|finalized|auth_soft_deleted|completed|canceled|failed
  final String state;

  bool get isPending => state == 'pending';
}

/// 탈퇴 취소 결과. 실패 코드는 서버 정본:
/// NOT_FOUND | NOT_CANCELABLE | CANCEL_WINDOW_PASSED.
class DeletionCancelResult {
  const DeletionCancelResult({required this.ok, this.code, this.state});

  final bool ok;
  final String? code;
  final String? state;

  bool get windowPassed => code == 'CANCEL_WINDOW_PASSED';
  bool get notCancelable => code == 'NOT_CANCELABLE';
  bool get notFound => code == 'NOT_FOUND';
}

/// 앱 내 탈퇴가 아직 서버에서 열리지 않음(EXECUTE 권한 없음 — 42501).
/// 화면은 이 오류에서만 웹 진행 폴백을 안내한다.
class AccountDeletionUnavailable extends AppError {
  const AccountDeletionUnavailable({super.cause})
      : super('앱에서 바로 탈퇴할 수 없어요. 웹 페이지에서 진행해 주세요.');
}

/// 탈퇴 포트 — 테스트는 손코딩 fake 주입(실 staging 계정으로 실행 금지).
abstract class AccountDeletionPort {
  /// 탈퇴 요청(실요청: dry_run=false 명시). 이미 job 이 있으면 멱등 응답.
  Future<DeletionRequestResult> requestDeletion();

  /// pending + 취소창 이내에서만 성공. 판정은 서버가 한다(로컬 추정 금지).
  Future<DeletionCancelResult> cancelDeletion();
}

/// RPC 호출 포트 — Supabase 구체 호출을 숨겨 fake 테스트를 가능하게 한다
/// (실 staging 계정으로 삭제 RPC 를 실행하지 않는다).
abstract class AccountDeletionBackend {
  /// 현재 로그인 사용자 id. 없으면 throw.
  String currentUserId();

  Future<Object?> rpc(String fn, Map<String, dynamic> params);
}

/// Supabase 백엔드.
class SupabaseAccountDeletionBackend implements AccountDeletionBackend {
  const SupabaseAccountDeletionBackend();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  @override
  String currentUserId() {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) throw const AppError('로그인이 필요해요.');
    return id;
  }

  @override
  Future<Object?> rpc(String fn, Map<String, dynamic> params) =>
      _client.rpc(fn, params: params);
}

/// Supabase 구현.
class SupabaseAccountDeletionRepository implements AccountDeletionPort {
  const SupabaseAccountDeletionRepository({
    this.cancelableMinutes = 30,
    AccountDeletionBackend? backend,
  }) : _backendOverride = backend;

  /// 취소 가능 창(분) — 서버 기본과 동일 값을 명시 전달.
  final int cancelableMinutes;

  final AccountDeletionBackend? _backendOverride;

  AccountDeletionBackend get _backend =>
      _backendOverride ?? const SupabaseAccountDeletionBackend();

  @override
  Future<DeletionRequestResult> requestDeletion() async {
    final Object? data;
    try {
      data = await _backend.rpc(
        'account_deletion_request',
        <String, dynamic>{
          'p_user_id': _backend.currentUserId(),
          'p_cancelable_minutes': cancelableMinutes,
          // ★ 서버 기본값이 dry_run=true 라 명시하지 않으면 실탈퇴가 아니다.
          'p_dry_run': false,
        },
      );
    } catch (e) {
      throw _mapError(e);
    }
    if (data is! Map || data['ok'] != true || data['job_id'] is! String) {
      throw const AppError('탈퇴 요청 결과를 확인하지 못했어요. 다시 시도해 주세요.');
    }
    return DeletionRequestResult(
      existing: (data['existing'] as bool?) ?? false,
      jobId: data['job_id'] as String,
      state: (data['state'] as String?) ?? 'pending',
    );
  }

  @override
  Future<DeletionCancelResult> cancelDeletion() async {
    final Object? data;
    try {
      data = await _backend.rpc(
        'account_deletion_cancel',
        <String, dynamic>{'p_user_id': _backend.currentUserId()},
      );
    } catch (e) {
      throw _mapError(e);
    }
    if (data is! Map) {
      throw const AppError('취소 결과를 확인하지 못했어요. 다시 시도해 주세요.');
    }
    return DeletionCancelResult(
      ok: data['ok'] == true,
      code: data['code'] as String?,
      state: data['state'] as String?,
    );
  }

  /// 42501(permission denied) = 앱 경로 미개방 → 웹 폴백 안내용 typed error.
  Object _mapError(Object e) {
    if (e is PostgrestException &&
        (e.code == '42501' ||
            e.message.toLowerCase().contains('permission denied'))) {
      return AccountDeletionUnavailable(cause: e);
    }
    return e;
  }
}
