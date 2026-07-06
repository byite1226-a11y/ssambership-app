import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import 'app_notification.dart';

/// 알림 한 페이지(앱 범위 항목 + 더보기 여부).
class NotificationsPage {
  const NotificationsPage({required this.items, required this.hasMore});

  final List<AppNotification> items;
  final bool hasMore;
}

/// 알림 조회·읽음 레포지토리(주입 가능 — 테스트에서 fake).
///
/// ★ 조회·읽음만. 알림 '생성'은 서버/푸시 몫(앱은 만들지 않음).
///   본인 알림만(RLS) 다룬다.
abstract class NotificationsRepository {
  Future<NotificationsPage> fetch({int limit, int offset});
  Future<void> markRead(String id);
  Future<void> markAllRead(List<String> ids);
}

/// Supabase 구현. RLS('본인 알림만')에 의존한다.
class SupabaseNotificationsRepository implements NotificationsRepository {
  const SupabaseNotificationsRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  @override
  Future<NotificationsPage> fetch({int limit = 20, int offset = 0}) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('notifications')
        .select('id, type, body, is_read, read, created_at')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    // 앱 범위(질문방·구독·개별질문)만 남긴다. CR·환불·미지 유형은 제외.
    final List<AppNotification> items = rows
        .map(AppNotification.fromMap)
        .where((AppNotification n) => n.inAppScope)
        .toList();

    // 더보기 판단은 '원본 행 수' 기준(필터 전) — 필터로 줄어도 다음 페이지가 있을 수 있다.
    return NotificationsPage(items: items, hasMore: rows.length >= limit);
  }

  /// 현재 사용자 id. 읽음 처리의 본인 한정 필터에 쓴다(다른 쓰기 레포와 동일 규약
  /// — RLS 를 최종 방어로 두되 앱 계층에서도 본인 행만 대상).
  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<void> markRead(String id) async {
    final String? uid = _uid;
    if (uid == null) return; // 세션 없음 — 읽음 처리할 본인 알림도 없다.
    await _client
        .from('notifications')
        .update(<String, dynamic>{
          'is_read': true,
          'read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', uid);
  }

  @override
  Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    final String? uid = _uid;
    if (uid == null) return; // 세션 없음 — no-op.
    await _client
        .from('notifications')
        .update(<String, dynamic>{
          'is_read': true,
          'read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .inFilter('id', ids)
        .eq('user_id', uid);
  }
}
