import '../../core/supabase/supabase_client.dart';
import '../models/health_probe.dart';

/// 연결 점검 레포지토리(DoD#2). 임의 '공개' 테이블 1건 read 로 백엔드 연결을 확인한다.
///
/// 주의: 어떤 공개 테이블이 RLS 로 anon read 허용인지는 백엔드에 의존한다.
/// 후보 테이블을 순서대로 시도하고, 하나라도 read 성공하면 ok=true.
/// (실패해도 앱은 그대로 구동 — 빈 앱 원칙)
class HealthRepository {
  const HealthRepository();

  /// anon 으로 select 가능성이 높은 공개 후보(백엔드 RLS 에 맞춰 조정).
  static const List<String> _publicCandidates = <String>[
    'subjects',
    'cash_topup_packages',
    'major_category_catalog',
    'school_tier_catalog',
  ];

  Future<HealthProbe> probe() async {
    final client = SupabaseInit.clientOrNull;
    if (client == null) {
      return const HealthProbe(ok: false, detail: 'supabase not initialized');
    }
    for (final String table in _publicCandidates) {
      try {
        final List<dynamic> rows =
            await client.from(table).select('*').limit(1);
        return HealthProbe(ok: true, sampleCount: rows.length, detail: table);
      } catch (_) {
        // 다음 후보 시도
        continue;
      }
    }
    return const HealthProbe(ok: false, detail: 'no readable public table');
  }
}
