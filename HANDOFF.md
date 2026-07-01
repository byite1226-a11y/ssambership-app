# 쌤버십 앱 인수인계 문서

> 이 문서 하나만 읽으면 남은 **설정·연결·출시**를 이어받을 수 있도록 정리했습니다.
> 비개발자도 이해할 수 있게 "무엇을/왜/어디에" 순서로 쓰되, 개발자용 **정확한 파일 경로·상수명**을 병기합니다.
> 코드에서 실제로 확인한 값만 적었고, 확인 못 한 항목은 **(확인 필요)** 로 표시했습니다.
> (기존 `lib/core/push/HANDOFF.md` 의 내용은 이 문서 3-4)에 흡수·통합했습니다. 원본 파일은 상세 참고용으로 남겨둡니다.)

---

## 1. 개요

- **무엇**: 기존 웹(Next.js, `ssambership_web`, 별도 저장소)의 **컴패니언 모바일 앱**. Flutter 단일 코드베이스로 Android·iOS 동시 타깃. 구독형 멘토 Q&A(질문방) 중심.
- **핵심 원칙**
  - **Commerce-Zero**: 앱 안에서 결제·가격 입력·구매를 **하지 않는다**. 구독·충전·정산 등 돈이 오가는 동선은 **웹 페이지를 여는 것**으로만 처리한다.
  - **웹과 백엔드 공유**: 새 백엔드를 만들지 않고 **웹과 같은 Supabase 1개**를 읽기 중심으로 사용한다(RLS 의존).
  - **색·디자인은 동업자 소관**: `lib/design/tokens/color_tokens.dart` 의 색 토큰은 **임시 placeholder hex**다. **통째로 갈아엎지 말고** 값만 확정해서 교체한다(구조·역할명 유지).
  - **표시 규칙**: 화면에 내부 DB명·UUID·이벤트 코드·딥링크 경로·영문 코드값 노출 금지(과목·상태 등은 한글 매핑 사용).
- **위치**: 앱 = `C:\dev\ssambership_app`. 웹 = 별도 저장소(README 기준 `ssambership_web`), **DB(Supabase)는 앱과 공유**.
- **완성 현황**: 하단 **5탭 전부** 구현(질문방·커뮤니티·멘토찾기·알림·마이페이지) + **위젯/로직 테스트 121개 전부 통과**(실제 DB·네트워크 없이 mock). `flutter analyze lib/` 에러 0.

---

## 2. 완성된 것 (S0~S12, 세션별)

| 세션 | 내용 |
|---|---|
| **S0** | Flutter 스캐폴드 — 모듈 구조·라우팅(빈 5탭)·Supabase(로컬)·색토큰/상수/과목매핑 |
| **S1** | 디자인 시스템 공통 위젯 10종(AppCard·InitialAvatar·AppBadge·StatusPill·Primary/SecondaryButton·ChipScroll·EmptyState 등) + dev 위젯 갤러리 |
| **S2** | 이메일 로그인·세션·역할(student/mentor/admin/guest)·계정상태 분기 + 게스트 둘러보기(커뮤니티·멘토찾기) + 마이페이지 로그아웃/사용자정보 |
| **S3** | 질문방 데이터 계층(모델·레포·RLS 검증) — 실제 스키마 기준 |
| **S4** | 학생 질문방 화면(목록→멘토방홈→질문영역→채팅→연결노트), 상태 라벨 웹 기준 |
| **S5** | 멘토 질문방 화면(학생목록→학생방홈→질문목록탭→답변→연결노트) |
| **S6** | 질문방 실시간·이미지첨부·연결노트 저장(인프라 있으면 연결, 없으면 골격+인수인계) |
| **S7** | 푸시 인프라 클라이언트 골격(Firebase·서버는 인수인계) |
| **S8** | 알림 센터(목록·읽음·유형필터·딥링크, CR/환불 제외) |
| **S9** | 커뮤니티 열람·댓글(숏폼/게시판/내활동, 작성은 웹) |
| **S10** | 멘토 찾기(열람·상세, 구독은 웹브릿지) |
| **S11** | 마이페이지 보강(구독현황·캐시조회·설정, 결제는 웹) |
| **S12** | 웹 브릿지 통일(구독·충전·결제관리 동선, URL 상수화 — 미확정 시 안내 폴백) |

> 모두 로컬 `master` 에 커밋됨. **원격(remote) 저장소는 아직 없음** — 백업/공유하려면 remote 추가 후 push 필요.

---

## 3. 동업자가 할 일 (우선순위 순)

각 항목: **왜 / 어디에 무엇을 / 하면 무엇이 켜지나** + 실제 코드 위치.

### 3-1. 웹 URL 확정 (가장 쉬움, 즉시 효과) ⭐
- **왜**: 앱의 모든 결제/구독/충전/정산 버튼이 "웹에서 진행돼요 (준비 중)" 안내만 띄우는 상태. 웹 도메인이 미확정이라서.
- **어디에 무엇을**: `lib/core/web_bridge/web_bridge_config.dart`
  - `static const String baseUrl = '';` **(line 14)** → 여기에 운영/스테이징 웹 도메인 입력 (예: `https://app.ssambership.com`). **가짜 URL 하드코딩 금지** — 확정값만.
  - 경로 상수 (line 17~21, 실제 웹 라우트와 다르면 함께 확정):
    `subscribePath='/subscribe'`, `rechargePath='/wallet/charge'`, `billingManagePath='/account/billing'`, `payoutManagePath='/mentor/payouts'`, `profileEditPath='/mentor/profile'`
- **하면**: `baseUrl` 한 곳만 채우면 **전체 결제 동선이 자동으로 실제 웹 열기로 전환**된다(외부 브라우저). 비어 있으면 안내 폴백 유지(`isConfigured`, line 24).
- **구조**: 서비스 `lib/core/web_bridge/web_bridge.dart`(`WebBridge`, launcher 주입 가능), 화면 헬퍼 `web_bridge_actions.dart`(`openSubscribeWeb`/`openRechargeWeb`/`openBillingManageWeb`/`openPayoutManageWeb`/`openProfileEditWeb`). 모든 화면이 이 헬퍼만 호출한다(중복 없음).
- **(선택) 웹→앱 복귀 딥링크**: 결제 완료 후 앱 복귀 스킴은 미구현(핵심은 "웹 열기"까지). 필요 시 앱 스킴 등록(모바일 빌드) + 콜백 라우트 설계.

### 3-2. 이미지 첨부 (Storage 버킷 + image_picker)
- **왜**: 질문방 채팅에 첨부 버튼·미리보기·업로드 코드는 완성됐지만 **저장소 버킷이 없고**, **이미지 선택기(image_picker)가 미도입**이라 실제 첨부는 보류 상태.
- **어디에 무엇을**: `lib/features/question_room/data/attachments/attachment_upload.dart`
  1. Supabase Storage에 **버킷 생성**(이름: `SupabaseAttachmentUploader.bucket = 'question-attachments'`, line 93 — 실제 확정 이름으로 맞출 것) + **"방 참여자만 read/write" 정책**. 그 뒤 `static const bool _storageReady = false;` **(line 96)** → `true`.
  2. `pubspec.yaml` 에 `image_picker` 추가 + Android/iOS 권한 설정. `DisabledImagePicker`(line 61, `isAvailable=false`) 대신 실제 `ImagePickerPort` 구현을 화면에 주입.
- **하면**: 첨부 버튼 → 이미지 선택 → 미리보기 → 업로드 + `question_attachments` 행 생성 → 채팅 표시(이미지 뷰어는 서명 URL 필요, 추가 구현).
- **제약(고정)**: 업로드 제한 문구 `kAttachmentRestrictionText`(line 10, 교재 PDF 등 저작권 자료 금지), 최대 5MB(`kMaxAttachmentBytes`, line 23), 이미지 형식만. `question_attachments` 컬럼: `thread_id·message_id·storage_path·file_name·mime_type`.

### 3-3. 실시간(Realtime) publication 확인
- **왜**: 채팅 실시간 구독 코드는 완성. Realtime **서비스는 가동 중**이나, 대상 테이블이 publication에 포함됐는지 미확인.
- **어디에 무엇을**: Supabase에서 `question_messages`·`question_threads` 가 **`supabase_realtime` publication에 포함**됐는지 확인/추가.
  - 구독 구현: `lib/features/question_room/data/thread_realtime.dart`(`SupabaseThreadRealtime`, `onPostgresChanges`).
- **하면**: 새 메시지·상태 변경이 **새로고침 없이 즉시** 반영. 미포함이어도 앱은 **폴백**으로 동작함 — 전송 후 재조회 + AppBar **새로고침 버튼**(`chat_screen.dart:_refresh` line 109 / 버튼 line 196, `mentor_answer_screen.dart` 동일).

### 3-4. 푸시 알림 (FCM) — S7 골격 활성화
- **왜**: 클라이언트 **골격만** 있음(포트 기본이 `Disabled/Noop`, Firebase 미도입, 서버 미배포). 아래를 채워야 실제 발송/수신.
- **어디에 무엇을** (`lib/core/push/`, 상세 원본: `lib/core/push/HANDOFF.md`):
  1. **Firebase 도입**: `pubspec.yaml` 에 `firebase_core`·`firebase_messaging` 추가(현재 없음). `flutterfire configure`(→ `firebase_options.dart`), `Firebase.initializeApp()`, Android `google-services.json`·Gradle 플러그인·`POST_NOTIFICATIONS`(Android 13+). 그 뒤 `PushTokenProvider`/`PushPermissionPort` 실제 구현 주입.
  2. **device_tokens 테이블 생성**(현재 미존재) → `SupabaseDeviceTokenRegistrar._tableExists = false` **(device_token_registrar.dart:13)** → `true`. DDL은 `lib/core/push/HANDOFF.md`(테이블 `device_tokens`, 컬럼 `user_id·token·platform·created_at·updated_at`, RLS 본인 토큰만).
  3. **Edge Function `send-push` 배포** → `EdgeFunctionPushSender._deployed = false` **(edge_function_push_sender.dart:17)** → `true`. 함수명 상수 `functionName = 'send-push'`(line 14). 입력 `{to_user_id, title, body, data}`.
  4. **발송 트리거 연결**(현재 **미연결** — 메서드만 존재): `lib/core/push/push_trigger.dart` 의
     `onMentorAnswered(...)` / `onNewQuestionForMentor(...)` / `onNewMessageForStudent(...)` 를 **질문방 이벤트 성공 직후** 호출(멘토 답변 전송·학생 새 질문/메시지). 상대 user_id 는 `mentor_student_rooms.student_id/mentor_id` 로 구함.
  5. **"알림 다시 켜기"**: `PushService.instance.requestPermissionAgain(userId: ...)` 를 마이페이지(S11) 설정에 연결.
- **하면**: 권한 팝업 → 토큰 발급/등록 → 답변 등 이벤트 → 푸시 수신 → 탭 시 관련 화면 이동. **실기기 검증 필요**(에뮬레이터는 FCM 제한).

### 3-5. 색·디자인 확정
- **왜**: 색 토큰 hex가 임시 placeholder. 화면 레이아웃/기능은 완성이나 최종 비주얼 미확정.
- **어디에 무엇을**: `lib/design/tokens/color_tokens.dart` — **역할명·구조는 유지**하고 hex만 확정값으로 교체(role: `page/surface/elevated`, `primary/secondary/muted`, `accent/accentMuted`, `success/warning/danger`, `border`). 단일 스카이 강조 + 시맨틱 유지. 필요 시 화면별 미세 조정.
- 레퍼런스: 토스 + 클래스101. **맞춤의뢰(CR)는 앱 범위 밖**이므로 관련 디자인 불필요.

### 3-6. 빌드·출시
- **네이티브 폴더**: `android/`·`ios/` (현재 untracked 상태로 존재). 없거나 갱신 필요 시:
  `flutter create . --org com.ssambership --project-name ssambership_app --platforms=android,ios` (기존 `lib/`·`pubspec.yaml` 보존, 누락 폴더만 생성). 패키지명 `com.ssambership.app` 권장.
- **.env 원격 전환**(출시): 로컬 → 원격 production 값 교체(README 참조)
  `SUPABASE_URL=https://<project-ref>.supabase.co` / `SUPABASE_ANON_KEY=<remote-anon-key>`. 원격이면 플랫폼 분기 없이 그대로 사용.
- **Android**: 릴리스 빌드·서명 키·Play Store 등록. **iOS**: 번들ID·서명·App Store 등록.

---

## 4. 의도적으로 제외한 것 (버그 아님)

- **맞춤의뢰(CR)·개별질문(IQ)·관리자·회원가입 폼**: 앱 범위 밖(README 핵심 원칙 "제외, 흔적 없이"). 알림·통계·메뉴에서도 노출하지 않음(예: 알림 유형 분류가 CR/환불/IQ를 `NotificationKind.other` 로 숨김 — `lib/features/notifications/data/app_notification.dart`).
- **잔여 질문수(주간 문항수) 숫자 표기 보류**: 값 미확정(특히 프리미엄 FUP). 지금은 숫자 대신 **구독 상태**로 표기(날조 금지). 확정되면 `lib/shared/constants/plan_constants.dart` 의 `planWeeklyQuestionQuota`(현재 전부 `null`)·`planLabels`(현재 전부 `''`)·`planMonthlyPriceCash`(현재 `null`)를 채우면 활성. 구독 요약의 `remaining`도 현재 `null`(`lib/core/entitlement/subscription_summary.dart`).
- **관리자 계정**: 앱에서 접근 시 차단(`AccessState.blocked`) — 학생·멘토 전용.

---

## 5. 하지 말 것 (지뢰)

- **`color_tokens.dart` 통째 교체 금지** — 역할 구조 유지, hex 값만 확정 교체.
- **미확정 가격·URL 하드코딩(날조) 금지** — 값이 없으면 비우고 안내. `baseUrl`·요금제 값이 대표 예.
- **앱 안에 결제/구매/가격입력 화면 금지** — 모든 결제는 웹 브릿지(웹으로만).
- **메시지·첨부는 append 전용** — 수정/삭제 기능·컬럼 없음(DB·모델 모두). 새로 추가하지 말 것.
- **service_role 키를 앱/클라이언트에 넣지 말 것** — 앱은 anon key + RLS만. (검증용 조회도 서버측에서.)
- **웹 저장소(ssambership_web) 구조를 앱에서 복제/침범 금지** — DB만 공유, 로직은 각자.

---

## 6. 검증·실행

- **테스트**: `flutter test` → **121개 전부 통과**(실제 DB·네트워크 없이 mock/fake 주입). `flutter analyze lib/` 에러 0. 코드 변경 후 이 둘을 유지할 것.
- **로컬 실행**: 웹 서버 모드 권장 — `flutter run -d web-server --web-port 5599` (`http://127.0.0.1:5599`). `-d chrome` 직접 구동은 이 환경에서 불안정하니 지양(URL을 브라우저에 직접 붙여 확인).
- **백엔드**: 개발은 **웹과 공유하는 로컬 Supabase**(`http://127.0.0.1:54321`). 앱 `.env` 의 `SUPABASE_URL` 이 웹 로컬 스택과 일치해야 함. URL은 플랫폼별 자동 분기(`lib/core/config/app_config.dart`: Android 에뮬 `10.0.2.2`, iOS/데스크탑 `127.0.0.1`, 실기기 `.env` `SUPABASE_URL_LAN`).
- **로컬 테스트 계정**: **웹 시드에 정의됨**(앱 저장소엔 계정 목록 없음 — **정확한 값은 웹 시드/`users` 테이블에서 확인 필요**). 시드 사용자 예: 학생/멘토(가격설정·가격미설정 멘토, 시드멘토1~16)·관리자. 관리자로는 앱 로그인이 **차단**된다(정상). 오너 제공 예시 계정(예: `local.student@…`, `local.mentor.priced@…`)의 정확한 주소·비밀번호는 웹 시드 기준으로 확인.
- **로컬 스키마 확인법**(참고): MCP로는 로컬 프로젝트가 안 잡히므로, PostgREST OpenAPI를 anon 키로 조회 — `GET http://127.0.0.1:54321/rest/v1/` (헤더 `apikey`/`Authorization: Bearer <anon>`). RLS로 가려진 표는 anon으로 개수/행이 안 보이는 게 정상(삭제 아님).

---

## 7. 프로젝트 구조

```
lib/
  app/        라우팅(router)·루트앱·홈셸(home_shell, 5탭)·진입가드(entry_guard)·탭이동(app_tabs=딥링크 채널)
  core/       supabase/ · config/(app_config) · auth/(AuthService·역할·계정상태) ·
              entitlement/(구독요약) · web_bridge/(★결제 동선 단일 소스) · push/(푸시 골격) · deeplink/
  design/     tokens/(color_tokens·typography) · widgets/(공통 10종)
  features/   auth/ onboarding/ question_room/ community/ mentors/ notifications/ mypage/
              (각 feature: data/ 모델·레포, ui/ 화면·위젯 — 한 파일에 안 몰기)
  shared/     constants/(app_constants·plan_constants) · format/(Formatters) · labels/ · errors/
  data/       mappings/(subject_labels 한글 매핑)
test/         위젯·로직 테스트(121개, DB 비의존). 폴더: data/ widgets/ screens/ notifications/ web_bridge/ mypage/ community/ push/ labels/
```

- **탭 딥링크**: 알림 등에서 `TabNavigator.go(AppTab.questionRoom|myPage|…)`(`lib/app/app_tabs.dart`) → `HomeShell` 이 수신해 탭 전환. (정확한 thread 딥링크가 아니라 관련 **탭 이동** — 필요 시 개선 여지. `mentors`/`mypage` 상단의 `TODO(S10/S11)` 라우트 주석은 탭이 이미 HomeShell에 연결돼 있어 **실제 변경 불필요**한 참고 표시임.)

---

### 인수인계 요약 (한 줄씩)
1. `web_bridge_config.dart` `baseUrl` 채우기 → 결제 동선 즉시 켜짐.
2. Storage 버킷 생성 + `_storageReady=true`, image_picker 도입 → 이미지 첨부 켜짐.
3. `supabase_realtime` publication에 질문 테이블 포함 → 실시간 켜짐(없어도 폴백 동작).
4. Firebase 도입 + `device_tokens` DDL(`_tableExists=true`) + `send-push` 배포(`_deployed=true`) + `PushTrigger` 연결 → 푸시 켜짐.
5. `color_tokens.dart` hex 확정.
6. `.env` 원격 전환 + Android/iOS 빌드·서명·스토어 등록.
