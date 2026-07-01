import '../supabase/supabase_client.dart';
import 'push_ports.dart';

/// 디바이스 토큰을 `device_tokens` 에 등록/해제하는 Supabase 골격.
///
/// ★ introspection 결과 `device_tokens` 테이블이 아직 없다 → [isReady]=false 로 건너뛴다.
///   테이블 생성(인수인계, HANDOFF.md의 DDL)과 firebase_messaging 도입 후 [_tableExists]=true
///   로 바꾸면 아래 upsert/delete 가 그대로 동작한다(로직은 미리 작성됨).
class SupabaseDeviceTokenRegistrar implements DeviceTokenRegistrarPort {
  const SupabaseDeviceTokenRegistrar();

  /// device_tokens 테이블 존재 여부(현재 미존재). 생성 후 true 로.
  static const bool _tableExists = false;

  @override
  bool get isReady => _tableExists && SupabaseInit.isReady;

  @override
  Future<void> register({
    required String userId,
    required String token,
    String platform = 'android',
  }) async {
    if (!isReady) return; // 테이블/백엔드 미준비 → 등록 생략(인수인계).
    final client = SupabaseInit.clientOrNull;
    if (client == null) return;
    // token 고유키로 upsert — 같은 기기 재로그인 시 user_id 갱신.
    await client.from('device_tokens').upsert(
      <String, dynamic>{
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );
  }

  @override
  Future<void> unregister({required String token}) async {
    if (!isReady) return;
    final client = SupabaseInit.clientOrNull;
    if (client == null) return;
    await client.from('device_tokens').delete().eq('token', token);
  }
}
