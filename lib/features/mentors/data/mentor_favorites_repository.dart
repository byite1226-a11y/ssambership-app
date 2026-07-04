import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

/// 멘토 찜(favorites) 레포지토리 — 본인(user_id) 행만 다룬다(RLS 신뢰).
///
/// 테이블: `favorites(user_id, mentor_id)`. 조회/추가/삭제만.
/// ★ RLS/컬럼/네트워크 실패는 삼켜 화면 흐름을 막지 않는다(빈 결과·false 폴백).
class MentorFavoritesRepository {
  const MentorFavoritesRepository();

  static const String _table = 'favorites';

  SupabaseClient? get _client => SupabaseInit.clientOrNull;
  String? get _uid => _client?.auth.currentUser?.id;

  /// 로그인 여부(비로그인 시 찜 대신 로그인 유도).
  bool get isLoggedIn => _uid != null;

  /// 내가 찜한 멘토 id 집합(비로그인/실패 시 빈 집합).
  Future<Set<String>> myFavoriteMentorIds() async {
    final SupabaseClient? c = _client;
    final String? uid = _uid;
    if (c == null || uid == null) return <String>{};
    try {
      final List<Map<String, dynamic>> rows =
          await c.from(_table).select('mentor_id').eq('user_id', uid);
      return <String>{
        for (final Map<String, dynamic> r in rows)
          if (r['mentor_id'] != null) r['mentor_id'] as String,
      };
    } catch (_) {
      return <String>{};
    }
  }

  /// 찜 추가. 성공/이미 찜(중복)이면 true. 비로그인/실패면 false.
  Future<bool> add(String mentorId) async {
    final SupabaseClient? c = _client;
    final String? uid = _uid;
    if (c == null || uid == null) return false;
    try {
      await c.from(_table).insert(<String, dynamic>{
        'user_id': uid,
        'mentor_id': mentorId,
      });
      return true;
    } catch (e) {
      // 유니크 위반(이미 찜)은 성공으로 간주.
      final String m = e.toString().toLowerCase();
      return m.contains('duplicate') || m.contains('unique');
    }
  }

  /// 찜 해제. 성공/비로그인 아님이면 true, 실패면 false.
  Future<bool> remove(String mentorId) async {
    final SupabaseClient? c = _client;
    final String? uid = _uid;
    if (c == null || uid == null) return false;
    try {
      await c
          .from(_table)
          .delete()
          .eq('user_id', uid)
          .eq('mentor_id', mentorId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
