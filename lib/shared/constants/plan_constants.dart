/// 요금제 관련 상수. (2026-07 오너 확정값 주입 — 웹 실코드와 대조 완료)
///
/// ⚠️ Commerce-Zero: 앱은 가격/구매 UI를 노출하지 않는다. 아래 값들은 '표시 매핑/안내'
/// 용도로만 존재하며, 가격을 결제 화면에 쓰지 말 것(웹으로만 연결).
library;

/// 요금제 식별 키 (내부용 — 화면에 영문 코드 노출 금지, 라벨은 [planLabels] 사용).
enum PlanTier { limited, standard, premium }

/// 요금제 한글 라벨 (2026-07 확정 — 웹 subscribePlanCatalog.ts 와 동일 표기).
const Map<PlanTier, String> planLabels = <PlanTier, String>{
  PlanTier.limited: '라이트',
  PlanTier.standard: '스탠다드',
  PlanTier.premium: '프리미엄',
};

/// 월 구독 가격(캐시). ★ 멘토별 변동가 — 앱은 가격을 표시하지 않음(Commerce-Zero),
/// 단일 상수 비성립. null 고정(키만 유지). 가격이 필요한 흐름은 web_bridge 로 웹을 연다.
const Map<PlanTier, int?> planMonthlyPriceCash = <PlanTier, int?>{
  PlanTier.limited: null,
  PlanTier.standard: null,
  PlanTier.premium: null,
};

/// 주간 문항 수 (2026-07 확정 — 웹 DB 정본 032/065 와 동일: 라이트 4·스탠다드 9).
/// ★ premium 은 null 유지 — 표시 레이어에서 "무제한" 문구로 처리한다.
///   999 등 내부 표현값 주입 금지(화면 노출 사고 방지).
const Map<PlanTier, int?> planWeeklyQuestionQuota = <PlanTier, int?>{
  PlanTier.limited: 4,
  PlanTier.standard: 9,
  PlanTier.premium: null,
};
