/// 커머스 제로 정책 — 결제 유도(스티어링) 단일 소스.
///
/// ★ 앱은 결제/구매를 유도하지 않는다(스토어 정책). 구독·충전의 '구매 유도' 진입점은
///   안내로 대체한다. 관리 링크(구독 관리·정산 관리)는 유지한다.
///   정책이 바뀌면 [kInAppPaymentSteeringEnabled] 한 곳으로 재개 여부를 제어한다.
library;

/// 앱 내 결제 유도(구독·충전 '구매' 진입점) 노출 여부. false = 안내로 대체.
const bool kInAppPaymentSteeringEnabled = false;

/// 구독 유도 대체 안내(웹 언급 없이).
const String kSubscribeNoticeText = '구독 사용자 전용이에요';

/// 캐시 충전 유도 대체 안내(웹 언급 없이).
const String kRechargeNoticeText = '캐시 충전은 앱에서 지원하지 않아요';
