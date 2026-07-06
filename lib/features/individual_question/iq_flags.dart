/// 개별질문(IQ) 기능 스위치.
///
/// ★ 스토어 정책 유의: 기충전 캐시를 앱 안에서 디지털 재화(개별질문)에 소비하는
///   것은 Google Play 결제 정책 검토 대상이다(docs/PLAY_STORE_REVIEW_PLAN.md).
///   조회·답변 확인은 소비가 아니므로 항상 유지한다.
library;

/// 개별질문 기능 전체 노출(목록·상세 포함).
const bool kIndividualQuestionEnabled = true;

/// 학생의 '새 개별질문 작성(캐시 예치)' 진입점 노출.
///
/// ★ A안 확정(2026-07) — 첫 스토어 제출 빌드는 기본 off. dev/내부 테스트는
///   `--dart-define=IQ_CREATE_ENABLED=true` 로 켠다(컴파일 타임 주입).
///   on 전환 게이트 = docs/PLAY_STORE_REVIEW_PLAN.md 의 결제 정책 검토 완료.
const bool kIndividualQuestionCreateEnabled =
    bool.fromEnvironment('IQ_CREATE_ENABLED', defaultValue: false);
