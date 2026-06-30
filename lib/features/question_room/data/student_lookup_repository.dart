import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';

/// 학생 공개 표시 정보(이름만). 멘토 화면(S5)에서 쓴다.
///
/// ★ RLS상 멘토는 users 테이블의 학생 행을 직접 못 읽는다(본인 행만).
///   연결된 학생 이름은 SECURITY DEFINER RPC `get_mentor_student_nicknames`
///   (param: p_student_ids uuid[])로 가져온다 — S4의 mentor_user_public_v2 와 같은 방식.
///   잔여 질문수 등 숫자는 이 레이어가 만들지 않는다(구독 상태로만 표시).
class StudentPublic {
  const StudentPublic({required this.id, this.nickname, this.fullName});

  final String id;
  final String? nickname;
  final String? fullName;

  /// 화면 표시명(nickname 우선 → full_name → 폴백 '학생').
  String get displayName {
    final String n = nickname?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final String f = fullName?.trim() ?? '';
    if (f.isNotEmpty) return f;
    return '학생';
  }

  factory StudentPublic.fromMap(Map<String, dynamic> map) {
    return StudentPublic(
      id: map['id'] as String,
      nickname: map['nickname'] as String?,
      fullName: map['full_name'] as String?,
    );
  }
}

/// 학생 공개정보 조회 레포지토리(멘토용). RPC 한 번에 여러 학생을 받는다.
class StudentLookupRepository {
  const StudentLookupRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  /// 여러 학생 공개정보를 한 번에. id → StudentPublic.
  /// 비어 있으면 RPC 호출 없이 빈 맵.
  Future<Map<String, StudentPublic>> fetchMany(Iterable<String> ids) async {
    final List<String> unique = ids.toSet().toList();
    if (unique.isEmpty) return <String, StudentPublic>{};
    final dynamic res = await _client.rpc(
      'get_mentor_student_nicknames',
      params: <String, dynamic>{'p_student_ids': unique},
    );
    final Map<String, StudentPublic> out = <String, StudentPublic>{};
    if (res is List) {
      for (final dynamic row in res) {
        if (row is Map<String, dynamic>) {
          final StudentPublic s = StudentPublic.fromMap(row);
          out[s.id] = s;
        }
      }
    }
    return out;
  }

  /// 학생 1명 공개정보. 없으면 null.
  Future<StudentPublic?> fetch(String studentId) async {
    final Map<String, StudentPublic> m = await fetchMany(<String>[studentId]);
    return m[studentId];
  }
}
