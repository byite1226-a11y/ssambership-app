/// 딥링크 처리(자리). 외부 경로/스킴은 화면에 노출하지 않고 내부에서만 라우팅에 매핑.
/// S0 에서는 골격만 — 실제 수신/파싱은 후속 세션.
library;

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  /// 앱 시작 시 1회 초기화(자리).
  Future<void> initialize() async {
    // TODO: 딥링크 스트림 구독 + 내부 라우트 매핑(경로 문자열은 화면 비노출).
  }
}
