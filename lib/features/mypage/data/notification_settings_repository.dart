import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

/// 알림 설정(켜기/끄기) 저장·로드. ★ DB 스키마를 만들지 않는다 — 이미 있으면 사용, 없으면 graceful.
///
/// 저장 위치(오너가 Supabase에서 준비): `users.notification_enabled`(boolean).
/// - 컬럼/권한이 아직 없으면 read/write 가 에러 → 조용히 폴백(null/false)해 화면은 로컬 상태만 유지.
/// - 오너가 컬럼(+RLS 본인 update)을 추가하면 코드 변경 없이 자동으로 영속화된다.
class NotificationSettingsRepository {
  const NotificationSettingsRepository();

  /// ★ 오너 확인 지점: 실제 테이블/컬럼명과 맞출 것(현재는 합리적 기본값).
  static const String table = 'users';
  static const String column = 'notification_enabled';

  SupabaseClient? get _client => SupabaseInit.clientOrNull;
  String? get _uid => _client?.auth.currentUser?.id;

  /// 저장된 값 로드. 없거나(컬럼 미존재) 실패면 null → 호출부가 기본값 유지.
  Future<bool?> loadEnabled() async {
    final SupabaseClient? c = _client;
    final String? id = _uid;
    if (c == null || id == null) return null;
    try {
      final Map<String, dynamic>? row =
          await c.from(table).select(column).eq('id', id).maybeSingle();
      final Object? v = row?[column];
      return v is bool ? v : null;
    } catch (_) {
      return null; // 컬럼 미존재/권한 등 → 조용히 폴백.
    }
  }

  /// 저장 시도. 성공 true, 실패(컬럼 미존재·권한 등) false → 호출부가 "준비 중" 안내 후 로컬 유지.
  Future<bool> saveEnabled(bool enabled) async {
    final SupabaseClient? c = _client;
    final String? id = _uid;
    if (c == null || id == null) return false;
    try {
      await c.from(table).update(<String, dynamic>{column: enabled}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
