/// 푸시 알림(자리). S0 에서는 골격만 — 토큰 등록/수신은 후속 세션.
library;

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  /// 권한 요청 + 토큰 등록(자리).
  Future<void> initialize() async {
    // TODO: 푸시 권한/토큰 등록(서버 연동). 화면에 토큰/내부 ID 노출 금지.
  }
}
