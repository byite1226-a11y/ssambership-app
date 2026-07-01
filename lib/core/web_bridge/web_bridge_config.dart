/// 웹 브릿지 URL 단일 소스(Commerce-Zero). ★ 결제/구독/충전/정산은 앱이 아니라 '웹'에서.
///
/// ══════════════════════════════════════════════════════════════════════
/// ★★ 오너 확정 지점 ★★
///   [baseUrl] 이 비어 있으면(미확정) 앱은 웹을 열지 않고 "웹에서 진행(준비 중)"만 안내한다.
///   운영/스테이징 도메인이 확정되면 [baseUrl] 한 곳만 채우면 전체 동선이 실제 열기로 전환된다.
///   예) 'https://app.ssambership.com' (← 확정값으로 교체. 가짜 URL 하드코딩 금지.)
///   경로(*Path)도 실제 웹 라우트와 다르면 함께 확정할 것.
/// ══════════════════════════════════════════════════════════════════════
class WebBridgeConfig {
  WebBridgeConfig._();

  /// 웹 베이스 URL(미확정 → 빈 문자열). 오너가 확정값으로 교체.
  static const String baseUrl = '';

  /// 결제/구독/충전/정산/프로필 웹 경로(오너 확정 대상). baseUrl 이 채워지면 이 경로로 열린다.
  static const String subscribePath = '/subscribe';
  static const String rechargePath = '/wallet/charge';
  static const String billingManagePath = '/account/billing';
  static const String payoutManagePath = '/mentor/payouts';
  static const String profileEditPath = '/mentor/profile';

  /// baseUrl 이 채워졌는지(=웹 열기 가능). 비면 안내 폴백.
  static bool get isConfigured => baseUrl.isNotEmpty;
}
