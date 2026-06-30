import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';

/// 멘토 공개 표시 정보(이름만). RLS상 users 테이블은 본인 행만 읽히므로,
/// 연결된 멘토 이름은 SECURITY DEFINER RPC(mentor_user_public_v2)로 가져온다.
class MentorPublic {
  const MentorPublic({required this.id, this.nickname, this.fullName});

  final String id;
  final String? nickname;
  final String? fullName;

  /// 화면 표시명(nickname 우선 → full_name → 폴백 '멘토').
  String get displayName {
    final String n = nickname?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final String f = fullName?.trim() ?? '';
    if (f.isNotEmpty) return f;
    return '멘토';
  }

  factory MentorPublic.fromMap(Map<String, dynamic> map) {
    return MentorPublic(
      id: map['id'] as String,
      nickname: map['nickname'] as String?,
      fullName: map['full_name'] as String?,
    );
  }
}

/// 멘토 공개정보 조회 레포지토리.
class MentorLookupRepository {
  const MentorLookupRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  /// 멘토 1명 공개정보. 없으면 null.
  Future<MentorPublic?> fetch(String mentorId) async {
    final dynamic res = await _client.rpc(
      'mentor_user_public_v2',
      params: <String, dynamic>{'p_mentor_id': mentorId},
    );
    if (res is List && res.isNotEmpty) {
      return MentorPublic.fromMap(res.first as Map<String, dynamic>);
    }
    return null;
  }

  /// 여러 멘토를 한 번에(개별 RPC 호출). id → MentorPublic.
  Future<Map<String, MentorPublic>> fetchMany(Iterable<String> ids) async {
    final Map<String, MentorPublic> out = <String, MentorPublic>{};
    for (final String id in ids.toSet()) {
      final MentorPublic? m = await fetch(id);
      if (m != null) out[id] = m;
    }
    return out;
  }
}
