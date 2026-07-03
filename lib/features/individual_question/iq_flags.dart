/// 개별질문(IQ) 기능 스위치.
///
/// ★ 스토어 정책 유의: 기충전 캐시를 앱 안에서 디지털 재화(개별질문)에 소비하는
///   것은 Google Play 결제 정책 검토 대상이다(docs/PLAY_STORE_REVIEW_PLAN.md).
///   스토어 제출 정책이 확정되기 전까지, 릴리즈 여부와 무관하게 이 스위치 하나로
///   '작성(예치)' 진입점을 끌 수 있게 한다. 조회·답변 확인은 소비가 아니므로 유지.
library;

/// 개별질문 기능 전체 노출(목록·상세 포함).
const bool kIndividualQuestionEnabled = true;

/// 학생의 '새 개별질문 작성(캐시 예치)' 진입점 노출.
/// 스토어 결제 정책 결정에 따라 false 로 내릴 수 있다.
const bool kIndividualQuestionCreateEnabled = true;
