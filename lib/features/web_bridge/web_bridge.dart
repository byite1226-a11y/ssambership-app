import 'package:url_launcher/url_launcher.dart';

/// 웹 브릿지: 결제(구독·캐시 충전)가 필요하면 '웹 페이지'만 연다.
///
/// ★ Commerce-Zero: 앱에는 결제·가격·구매 버튼·외부 결제 링크가 없다.
///   이 브릿지는 결제 행위를 하지 않고, 단지 웹의 해당 페이지를 외부 브라우저로 연다.
///   (구체 URL 은 미확정 — 키만 두고 값은 비움. 확정 후 채운다.)
class WebBridge {
  WebBridge._();

  /// 웹 베이스 URL(미확정). TODO: 운영/스테이징 웹 URL 로 채울 것(README).
  static const String webBaseUrl = '';

  /// 웹 경로(미확정). 결제/가격 숫자는 앱이 다루지 않는다.
  static const String subscribePath = ''; // TODO: 예) /subscribe
  static const String walletChargePath = ''; // TODO: 예) /wallet/charge

  /// 웹의 구독 페이지 열기(앱에서 결제하지 않음).
  static Future<bool> openSubscribeOnWeb() => _open(subscribePath);

  /// 웹의 캐시 충전 페이지 열기(앱에서 결제하지 않음).
  static Future<bool> openWalletChargeOnWeb() => _open(walletChargePath);

  static Future<bool> _open(String path) async {
    if (webBaseUrl.isEmpty || path.isEmpty) {
      // URL 미확정 — 아직 열지 않는다(안내만). 화면에 내부 경로 노출 금지.
      return false;
    }
    final Uri uri = Uri.parse('$webBaseUrl$path');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
