# v16 관리자 통합 QA 체크리스트

> 상태: **ADMIN_QA_READY_NOT_EXECUTED** — 이 환경에는 관리자 테스트 계정 로그인 수단이
> 없고, 계정/DB 임의 수정은 금지 사항이다. 정적 검증(코드 레벨)은 아래 §1에 기록,
> 실행 QA 는 관리자 계정이 준비된 환경에서 §2 를 수행한다.

## 1. 정적 검증(이번 세션 코드 레벨 확인 — 완료)

- **관리자 로그인 정책**: `AuthService.computeAccess` 가 admin 역할을 **차단**한다
  (이 앱은 학생·멘토 전용 — `auth_service.dart`, `test/auth/auth_access_test.dart` 고정).
- **관리자 기능 누출 0**: 앱에 moderation/blind/신고 처리 UI 없음. 리뷰 moderation 필드
  (`is_hidden/is_blinded/moderation_state/moderated_*`)를 쓰는 코드 0
  (유일한 reviews 접근은 읽기 전용 집계 1곳 — `mentor_directory_repository.dart`).
- **블라인드 리뷰 미노출**: 통계 집계 쿼리가 `moderation_state='visible' AND
  is_hidden=false AND is_blinded=false` 필터를 서버 RLS 와 이중으로 적용.
- **보호필드 전송 0**: 서버 트리거(`reviews_enforce_update`)가 최종 방어 —
  앱은 리뷰 UPDATE 경로 자체가 없다.
- **민감 서류 URL**: 멘토 승인 서류 등은 앱 화면에 노출 경로 없음(관리자 웹 전용).
  실행 QA 에서 admin 계정으로 재확인할 것.

## 2. 실행 QA (관리자 계정 필요 — 웹 관리자 화면 + 앱 교차)

- [ ] 관리자 계정으로 앱 로그인 시도 → 차단 화면(관리자는 웹 사용 안내), 크래시 0
- [ ] 웹에서 리뷰 blind 처리 → 앱 멘토 통계에서 즉시 제외되는지
- [ ] 웹에서 리뷰 blind 해제 → 앱 통계 복귀
- [ ] 신고된 게시글/댓글 숨김 처리 → 앱 커뮤니티 목록 미노출
- [ ] 사용자 suspended(+해제 시각) 처리 → 앱 차단 화면 + 해제 예정일 표기
- [ ] banned 처리 → 앱 영구 차단 문구
- [ ] 탈퇴 job locked/purging 계정 → 앱 진입 차단(재시도 아님 문구)
- [ ] 멘토 미승인 계정 질문 시도 → MENTOR_NOT_APPROVED 안내
- [ ] 관리자 웹의 서류 검토 URL 이 앱 어디에도 렌더되지 않는지(딥링크 포함)
