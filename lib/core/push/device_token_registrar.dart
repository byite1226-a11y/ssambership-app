import '../../shared/errors/app_error.dart';
import '../supabase/supabase_client.dart';
import 'push_ports.dart';

/// 디바이스 토큰 등록/철회 — Supabase 구현(스테이징 검증된 서버 계약, 2026-07-21).
///
/// - 등록: RPC `register_device_token(p_token, p_platform)` (SECURITY DEFINER).
///   반환 jsonb {ok, device_token_id}. ON CONFLICT(token) 시 현재 auth.uid() 로
///   원자적 재소유 + revoked_at 해제 → 계정 전환은 '재등록'만으로 끝난다.
///   platform 은 ios/android/web 만 유효(그 외 서버가 'unknown' 저장).
/// - 철회: `revoke_device_token` RPC 는 authenticated EXECUTE 권한이 없어 호출 금지.
///   대신 본인 행 직접 UPDATE(RLS device_tokens_modify_own) 로 revoked_at 마킹.
///   ★ 반드시 signOut '이전'(세션 유효 시점)에 호출해야 한다.
class SupabaseDeviceTokenRegistrar implements DeviceTokenRegistrarPort {
  const SupabaseDeviceTokenRegistrar();

  @override
  bool get isReady => SupabaseInit.isReady;

  @override
  Future<String?> register({
    required String token,
    required String platform,
  }) async {
    final client = SupabaseInit.clientOrNull;
    if (client == null) {
      throw const AppError('알림 등록에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
    final dynamic result = await client.rpc(
      'register_device_token',
      params: <String, dynamic>{'p_token': token, 'p_platform': platform},
    );
    if (result is Map && result['ok'] == true) {
      final Object? id = result['device_token_id'];
      return id?.toString();
    }
    // AUTH_REQUIRED/TOKEN_REQUIRED 등 — 호출부가 재시도 가능하도록 예외로 전파.
    // ★ 토큰 문자열/서버 원문을 메시지에 담지 않는다.
    throw const AppError('알림 등록에 실패했어요. 잠시 후 다시 시도해 주세요.');
  }

  @override
  Future<void> revoke({required String token}) async {
    final client = SupabaseInit.clientOrNull;
    if (client == null) return;
    final String? userId = client.auth.currentUser?.id;
    if (userId == null) return; // 세션 없음 — 철회 불가(서버 재소유 로직이 안전망).
    final String now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('device_tokens')
        .update(<String, dynamic>{'revoked_at': now, 'updated_at': now})
        .eq('token', token)
        .eq('user_id', userId);
  }
}
