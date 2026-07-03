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

  /// 웹 베이스 URL. ★끝 슬래시 없음 — buildUri 가 '$baseUrl$path'(path 는 '/…' 시작)로
  /// 조립하므로 슬래시를 붙이면 '//' 이중슬래시가 난다.
  static const String baseUrl = 'https://ssambership-web.vercel.app';

  /// 결제/구독/충전/정산/프로필 웹 경로. 실제 Next.js 라우트와 대조해 확정(2026-07 실측).
  static const String subscribePath = '/subscribe'; // app/(student)/subscribe
  static const String rechargePath = '/wallet/charge'; // app/(student)/wallet/charge
  static const String billingManagePath =
      '/subscriptions'; // app/(student)/subscriptions (구독 취소·관리)
  static const String payoutManagePath = '/mentor/payouts'; // app/(mentor)/mentor/payouts
  static const String profileEditPath = '/mentor/profile'; // app/(mentor)/mentor/profile

  /// 정보/지원/리뷰 웹 경로(마이페이지 행 배선용, 실측 라우트).
  static const String termsPath = '/legal/terms'; // app/(public)/legal/terms
  static const String privacyPath = '/legal/privacy'; // app/(public)/legal/privacy
  static const String supportPath = '/support'; // app/(public)/support (고객센터·FAQ 허브)
  static const String reviewsPath = '/mentor/reviews'; // app/(mentor)/mentor/reviews

  /// baseUrl 이 채워졌는지(=웹 열기 가능). 비면 안내 폴백.
  static bool get isConfigured => baseUrl.isNotEmpty;
}
