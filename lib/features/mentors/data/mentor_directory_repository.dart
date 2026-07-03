import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/entitlement/subscription_summary.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import 'mentor_models.dart';

/// 멘토 찾기(공개·열람 전용) 레포지토리.
///
/// 모두 공개 조회 가능한 소스만 사용한다:
/// - `mentor_directory_list_v2(p_limit)` : 공개 멘토 목록(id·표시명·상태·가입일)
/// - `mentor_profiles_for_directory_v2(p_ids)` : 공개 프로필(학교·과목·소개·인증)
/// - `mentor_plans` (is_active=true) : 요금제(가격 '표시'만)
/// - `get_mentor_avg_response_hours(p_mentor_id)` : 평균 답변시간(없으면 null)
/// 구독 여부는 본인 행만 보이는 subscriptions 를 [SubscriptionReader] 로 읽는다.
class MentorDirectoryRepository {
  const MentorDirectoryRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  /// 공개 멘토 목록. 디렉터리 → 프로필 → 활성 요금제를 묶어 한 행으로 만든다.
  Future<List<MentorListItem>> list({int limit = 20}) async {
    final dynamic dirRes = await _client.rpc(
      'mentor_directory_list_v2',
      params: <String, dynamic>{'p_limit': limit},
    );
    final List<MentorListItem> entries = <MentorListItem>[];
    if (dirRes is List) {
      for (final Object? row in dirRes) {
        if (row is Map<String, dynamic>) {
          entries.add(MentorListItem.fromDirectoryMap(row));
        }
      }
    }
    if (entries.isEmpty) return <MentorListItem>[];

    final List<String> ids =
        entries.map((MentorListItem e) => e.id).toList(growable: false);
    final Map<String, MentorProfileInfo> profiles = await _profiles(ids);
    final Map<String, List<MentorPlan>> plans = await _activePlans(ids);

    return entries
        .map((MentorListItem e) => e.copyWith(
              profile: profiles[e.id],
              plans: plans[e.id] ?? const <MentorPlan>[],
            ))
        .toList();
  }

  /// 상세 화면 추가 정보(평균 답변시간 + 내 구독 여부). 프로필·요금제는 목록에서
  /// 받은 항목을 재사용하므로 여기서는 부족한 부분만 채운다.
  Future<MentorDetailExtras> fetchExtras(String mentorId) async {
    num? avgHours;
    try {
      final dynamic r = await _client.rpc(
        'get_mentor_avg_response_hours',
        params: <String, dynamic>{'p_mentor_id': mentorId},
      );
      if (r is num) avgHours = r;
    } catch (_) {
      avgHours = null; // 통계 없음 → '신규 멘토'
    }

    bool subscribed = false;
    final String? uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final Map<String, SubscriptionSummary> subs =
            await SubscriptionReader.fetchForStudent(_client, uid);
        subscribed = subs[mentorId]?.isActive ?? false;
      } catch (_) {
        subscribed = false;
      }
    }

    return MentorDetailExtras(
      avgResponseHours: avgHours,
      alreadySubscribed: subscribed,
    );
  }

  Future<Map<String, MentorProfileInfo>> _profiles(List<String> ids) async {
    final Map<String, MentorProfileInfo> out = <String, MentorProfileInfo>{};
    final dynamic res = await _client.rpc(
      'mentor_profiles_for_directory_v2',
      params: <String, dynamic>{'p_ids': ids},
    );
    if (res is List) {
      for (final Object? row in res) {
        if (row is Map<String, dynamic>) {
          final MentorProfileInfo info = MentorProfileInfo.fromMap(row);
          out[info.userId] = info;
        }
      }
    }
    return out;
  }

  Future<Map<String, List<MentorPlan>>> _activePlans(List<String> ids) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('mentor_plans')
        .select('mentor_id, plan_tier, amount_cents, label')
        .inFilter('mentor_id', ids);

    final Map<String, List<MentorPlan>> out = <String, List<MentorPlan>>{};
    for (final Map<String, dynamic> r in rows) {
      final String? mentorId = r['mentor_id'] as String?;
      if (mentorId == null) continue;
      out.putIfAbsent(mentorId, () => <MentorPlan>[]).add(MentorPlan.fromMap(r));
    }
    return out;
  }
}
