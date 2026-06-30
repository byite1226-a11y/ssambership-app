/// 요금제 관련 상수.
///
/// ⚠️ Commerce-Zero: 앱은 가격/구매 UI를 노출하지 않는다. 아래 값들은 '표시 매핑/안내'
/// 용도로만 존재할 수 있으며, 가격·주간 문항수는 미확정이므로 '키만' 만들고 값은 비운다.
/// 확정 후 채우되, 가격을 결제 화면에 쓰지 말 것(웹으로만 연결).
library;

/// 요금제 식별 키 (내부용 — 화면에 영문 코드 노출 금지, 라벨은 [planLabels] 사용).
enum PlanTier { limited, standard, premium }

/// 요금제 한글 라벨 (확정 후 교체). TODO: 확정.
const Map<PlanTier, String> planLabels = <PlanTier, String>{
  PlanTier.limited: '', // TODO: 베이직 등 확정 라벨
  PlanTier.standard: '', // TODO
  PlanTier.premium: '', // TODO
};

/// 월 구독 가격(캐시). ⚠️ 미확정 + 앱 내 결제 금지 → 값 비움(키만).
/// 가격이 필요하면 web_bridge 로 웹을 열 뿐, 앱에서 숫자를 결제에 쓰지 않는다.
const Map<PlanTier, int?> planMonthlyPriceCash = <PlanTier, int?>{
  PlanTier.limited: null, // TODO
  PlanTier.standard: null, // TODO
  PlanTier.premium: null, // TODO
};

/// 주간 문항 수. ⚠️ 미확정(특히 프리미엄은 FUP) → 값 비움(키만).
const Map<PlanTier, int?> planWeeklyQuestionQuota = <PlanTier, int?>{
  PlanTier.limited: null, // TODO
  PlanTier.standard: null, // TODO
  PlanTier.premium: null, // TODO: 프리미엄 문항수 미확정(FUP)
};
