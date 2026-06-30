import 'package:supabase_flutter/supabase_flutter.dart';

/// 권한/구독 상태(읽기 전용).
///
/// ★ Commerce-Zero: 앱은 결제하지 않고 '상태를 읽기만' 한다.
///   구독/충전이 필요하면 web_bridge 로 웹을 연다.
class Entitlement {
  const Entitlement({
    this.hasActiveSubscription = false,
    this.planTier,
  });

  /// 활성 구독 여부(subscriptions.status == 'active').
  final bool hasActiveSubscription;

  /// 활성 구독의 plan_tier (limited|standard|premium). 없으면 null.
  final String? planTier;

  /// 앱 안에서 결제는 절대 하지 않는다(웹으로만 연결)을 명시하는 상수.
  static const bool inAppPurchaseEnabled = false;

  static const Entitlement none = Entitlement();
}

/// subscriptions 읽기 전용 리더(RLS: 당사자만).
class EntitlementReader {
  EntitlementReader._();

  /// 학생 본인의 활성 구독을 읽는다. status == 'active' 면 활성으로 본다.
  ///
  /// ※ past_due / cancel_scheduled 등 세밀한 정책은 지금 다루지 않는다(S3).
  ///   결제는 하지 않고 상태만 읽는다.
  static Future<Entitlement> fetchForStudent(
    SupabaseClient client,
    String studentId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows = await client
          .from('subscriptions')
          .select('status, plan_tier')
          .eq('student_id', studentId)
          .eq('status', 'active')
          .limit(1);
      if (rows.isEmpty) return Entitlement.none;
      final Map<String, dynamic> row = rows.first;
      return Entitlement(
        hasActiveSubscription: true,
        planTier: (row['plan_tier'] as String?)?.trim(),
      );
    } catch (_) {
      return Entitlement.none;
    }
  }
}
