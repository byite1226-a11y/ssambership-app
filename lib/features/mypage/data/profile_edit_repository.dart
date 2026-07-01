import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';

/// 프로필 수정(안전 필드만). ★ 역할(role)·이메일·id 등 시스템/민감 필드는 절대 건드리지 않는다.
/// DB 스키마 변경 없음 — 기존 users 테이블의 비민감 컬럼만 update(RLS: 본인 행).
class ProfileEditRepository {
  const ProfileEditRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) throw const AppError('로그인이 필요해요.');
    return id;
  }

  /// 표시명(nickname)·학년(grade_level)만 갱신. null 인 항목은 건드리지 않는다.
  /// 실패(권한·컬럼 등) 시 예외를 그대로 올려 호출부가 사용자에게 안내한다.
  Future<void> updateProfile({String? nickname, String? gradeLevel}) async {
    final Map<String, dynamic> patch = <String, dynamic>{};
    if (nickname != null) patch['nickname'] = nickname;
    if (gradeLevel != null) patch['grade_level'] = gradeLevel;
    if (patch.isEmpty) return; // 바뀐 것 없음.
    await _client.from('users').update(patch).eq('id', _uid);
  }
}
