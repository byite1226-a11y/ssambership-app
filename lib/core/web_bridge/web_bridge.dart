import 'package:url_launcher/url_launcher.dart';

import 'web_bridge_config.dart';

/// 웹 열기 결과. notConfigured = baseUrl 미확정(안내 폴백), failed = 열기 실패.
enum WebOpenResult { opened, notConfigured, failed }

/// URL 열기 함수(주입 가능 — 테스트에서 fake).
typedef UrlLauncher = Future<bool> Function(Uri uri);

/// 웹 브릿지 서비스 — 결제/구독/충전/정산/프로필 동선을 '웹으로만' 연다(Commerce-Zero).
///
/// ★ 앱은 결제/가격입력/구매를 하지 않는다. 이 서비스는 결제 행위를 하지 않고,
///   웹의 해당 페이지를 외부 브라우저로 여는 것뿐이다. URL 은 [WebBridgeConfig] 한 곳에서 온다.
///   baseUrl 미확정이면 아무 URL 도 만들지 않고 [WebOpenResult.notConfigured] 를 돌려준다(날조 없음).
class WebBridge {
  WebBridge({UrlLauncher? launcher, String? baseUrl})
      : _launcher = launcher ?? _defaultLauncher,
        _baseUrl = baseUrl ?? WebBridgeConfig.baseUrl;

  final UrlLauncher _launcher;
  final String _baseUrl;

  static Future<bool> _defaultLauncher(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool get isConfigured => _baseUrl.isNotEmpty;

  /// 구독(선택: 특정 멘토). mentorId 는 어떤 멘토 구독인지 맥락 전달용.
  Future<WebOpenResult> openSubscribe({String? mentorId, String source = 'app'}) {
    return _open(WebBridgeConfig.subscribePath, <String, String>{
      'src': source,
      if (mentorId != null && mentorId.isNotEmpty) 'mentor': mentorId,
    });
  }

  /// 캐시 충전.
  Future<WebOpenResult> openRecharge({String source = 'app'}) =>
      _open(WebBridgeConfig.rechargePath, <String, String>{'src': source});

  /// 결제·구독 관리(학생).
  Future<WebOpenResult> openBillingManage({String source = 'app'}) =>
      _open(WebBridgeConfig.billingManagePath, <String, String>{'src': source});

  /// 정산 관리(멘토).
  Future<WebOpenResult> openPayoutManage({String source = 'app'}) =>
      _open(WebBridgeConfig.payoutManagePath, <String, String>{'src': source});

  /// 프로필 편집(멘토 — 웹 우선).
  Future<WebOpenResult> openProfileEdit({String source = 'app'}) =>
      _open(WebBridgeConfig.profileEditPath, <String, String>{'src': source});

  /// 이용약관(정보 페이지).
  Future<WebOpenResult> openTerms({String source = 'app'}) =>
      _open(WebBridgeConfig.termsPath, <String, String>{'src': source});

  /// 개인정보처리방침(정보 페이지).
  Future<WebOpenResult> openPrivacy({String source = 'app'}) =>
      _open(WebBridgeConfig.privacyPath, <String, String>{'src': source});

  /// 고객지원 허브(FAQ·분쟁·환불·신고 안내).
  Future<WebOpenResult> openSupport({String source = 'app'}) =>
      _open(WebBridgeConfig.supportPath, <String, String>{'src': source});

  /// 리뷰(멘토 계정 기준).
  Future<WebOpenResult> openReviews({String source = 'app'}) =>
      _open(WebBridgeConfig.reviewsPath, <String, String>{'src': source});

  /// 회원 탈퇴(계정 삭제) — 웹 페이지만 연다(앱 내 삭제 흐름 없음).
  Future<WebOpenResult> openAccountDelete({String source = 'app'}) =>
      _open(WebBridgeConfig.accountDeletePath, <String, String>{'src': source});

  /// URL 조립(테스트/검토용 — 실제 열기와 동일한 규칙). baseUrl 미확정이면 null.
  Uri? buildUri(String path, [Map<String, String> query = const <String, String>{}]) {
    if (_baseUrl.isEmpty || path.isEmpty) return null;
    final Uri base = Uri.parse('$_baseUrl$path');
    if (query.isEmpty) return base;
    return base.replace(queryParameters: <String, String>{
      ...base.queryParameters,
      ...query,
    });
  }

  Future<WebOpenResult> _open(String path, Map<String, String> query) async {
    final Uri? uri = buildUri(path, query);
    if (uri == null) return WebOpenResult.notConfigured; // baseUrl 미확정 → 안내 폴백.
    final bool ok = await _launcher(uri);
    return ok ? WebOpenResult.opened : WebOpenResult.failed;
  }
}
