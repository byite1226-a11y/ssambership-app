# v16 실기기 통합 QA 체크리스트 (Android/iOS)

> 상태: **READY_NOT_EXECUTED** — 이 실행 환경에는 Android SDK/emulator(네트워크 정책이
> dl.google.com 차단)·macOS/Xcode·Firebase 설정 파일이 없다. 코드·테스트는 준비 완료,
> 아래 절차는 기기/맥/Firebase 파일이 갖춰진 환경에서 그대로 실행한다. PASS 위조 금지.

## 0. 사전 조건

- [ ] `android/app/google-services.json` 배치 (Firebase Android 앱: `com.ssambership.app`)
- [ ] `ios/Runner/GoogleService-Info.plist` 배치 (Firebase iOS 앱: `com.ssambership.app`)
- [ ] `android/app/build.gradle.kts` plugins 에 `com.google.gms.google-services` 추가
- [ ] (iOS) Xcode Push Notifications capability + `aps-environment` entitlement + APNs 키 등록
- [ ] (iOS) `cd ios && pod install`
- [ ] `.env` 에 staging SUPABASE_URL/ANON_KEY (운영 금지 — QA 는 staging)
- 절차 상세: `lib/core/push/HANDOFF.md`

## 1. Android (기기 또는 emulator, Android 13+)

### 푸시·토큰
- [ ] 첫 로그인 → POST_NOTIFICATIONS 권한 팝업 → 허용 → device_tokens 에 행 생성(user_id=본인)
- [ ] 권한 거부 → 등록 시도 없음(크래시 0) → 설정 화면에 '기기 알림 권한 꺼짐' 안내
- [ ] foreground 수신: question_answered 발생(웹에서 멘토 답변) → 앱 내 신호 수신
- [ ] background 수신 → 시스템 알림 표시 → 탭 → 질문방 탭 이동
- [ ] terminated(스와이프 종료) 수신 → 탭 → cold start → 질문방 탭 이동(1회)
- [ ] 같은 알림 재탭/중복 전달 → 이동 1회(중복 내비게이션 0)
- [ ] 미로그인 상태 알림 탭 → 로그인 → 대상 탭 1회 이동(15분 TTL 내)
- [ ] 로그아웃 → device_tokens.revoked_at 세팅 확인
- [ ] 계정 A 로그아웃 → 계정 B 로그인 → 같은 기기 토큰의 user_id 가 B 로 재소유
- [ ] 계정 B 에 A 의 pending 딥링크 미실행

### 기능
- [ ] 숏폼 상세: video_player 재생/일시정지/dispose(뒤로가기 후 오디오 잔류 0)
- [ ] 질문방 이미지 첨부: 촬영/갤러리/파일 → 5MB 초과 자동 축소 → 업로드 → 첨부 표시
- [ ] 첨부 등록 실패 유도(비행기 모드 전환) → 실패 안내 + pending 미리보기 유지 → 재시도 성공
- [ ] Storage 에 고아 객체 없음(등록 실패분 보상 삭제 확인)
- [ ] 첨부 파일 열기(서명 URL) → 외부 앱 → 1시간 경과 후 재열기(재서명)
- [ ] 웹브리지: 구독/약관/지원 → https://ssambership.com 만 열림, 타 도메인 차단 확인
- [ ] 계정탈퇴 화면: (grant 배포 전) '웹에서 진행' 폴백 노출 확인
- [ ] 알림 목록: 무한 스크롤(중복/누락 0), 모두 읽음, 설정 토글 저장/원복

## 2. iOS (macOS/Xcode 필요)

- [ ] `pod install` 성공(firebase_core/messaging/video_player pods 포함)
- [ ] Debug 빌드 + 실기기 설치
- [ ] 알림 권한 요청 팝업 → 허용 → APNs 토큰 발급 → device_tokens 등록
- [ ] foreground/background/terminated 수신 + 탭 이동(Android 와 동일 시나리오)
- [ ] video_player(AVFoundation) 재생
- [ ] image_picker 촬영/앨범 권한 문구(한글) 확인
- [ ] 첨부 업로드/서명 URL/웹브리지 — Android 와 동일 시나리오
- [ ] 딥링크 pending/중복 방지 — Android 와 동일 시나리오

## 3. 회귀(양 플랫폼 공통, staging 데이터)

- [ ] 질문 생성 → 주간 사용량 감소 · 한도 소진 시 차단 문구
- [ ] 멘토 첫 답변 → 학생 알림 수신 + 상태칩 '진행 중'
- [ ] 학생 확인 → '답변 완료' → 이후 메시지 전송 시 THREAD_LOCKED 안내
- [ ] 오답 표시/해제 토글
- [ ] IQ 취소(escrowed) → 지갑 잔액 복원(마이페이지 캐시 확인)
- [ ] IQ answered 상태에서 취소 버튼 미노출
