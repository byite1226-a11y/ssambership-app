/// 권한/구독 상태(자리). Commerce-Zero: 앱은 결제하지 않고 '상태를 읽기만' 한다.
/// 구독/충전이 필요하면 web_bridge 로 웹을 연다.
library;

class Entitlement {
  const Entitlement({
    this.hasActiveSubscription = false,
  });

  /// 활성 구독 여부(자리). 후속에서 서버 read 로 채움.
  final bool hasActiveSubscription;

  /// 앱 안에서 결제는 절대 하지 않는다(웹으로만 연결)을 명시하는 상수.
  static const bool inAppPurchaseEnabled = false;
}
