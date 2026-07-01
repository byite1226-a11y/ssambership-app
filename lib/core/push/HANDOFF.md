# 푸시 알림 인프라 — 동업자 인수인계 (S7)

이 디렉터리(`lib/core/push/`)는 **패키지·서버 없이 컴파일되는 클라이언트 골격**이다.
포트(추상)는 기본이 `Disabled/Noop` 이라 아무 것도 전송/등록하지 않는다.
실기기에서 실제로 동작시키려면 아래 4가지를 동업자가 채워야 한다.

> 안전 원칙: 앱은 결제/서버 인프라를 만들지 않는다. 아래 DDL·Edge Function은 **미적용 명세**다.

## 1) firebase_messaging 도입 (pubspec + 권한 설정)
- `pubspec.yaml` dev와 별개로 dependencies에 추가: `firebase_core`, `firebase_messaging`.
  (S7은 pubspec을 건드리지 않았다 — 병렬 충돌 방지.)
- `flutterfire configure` 로 `firebase_options.dart` 생성, `Firebase.initializeApp()` 를 main에 추가.
- Android: `android/app/google-services.json`, Gradle 플러그인, `POST_NOTIFICATIONS`(Android 13+) 권한.
- 그 뒤 포트 구현체 작성:
  - `PushTokenProvider` → `FirebaseMessaging.instance.getToken()` / `onTokenRefresh`.
  - `PushPermissionPort` → `FirebaseMessaging.instance.requestPermission()` 결과를 `PushPermissionStatus`로 매핑.
  - `PushService(instance)` 생성 시 위 구현체를 주입(또는 `instance` 정의 교체).

## 2) device_tokens 테이블 생성 (현재 **미존재** — introspection 확인됨)
`SupabaseDeviceTokenRegistrar._tableExists = false` 로 등록을 건너뛰고 있다.
아래 DDL로 테이블을 만든 뒤 `_tableExists = true` 로 바꾸면 upsert/delete가 동작한다.
(마이그레이션 적용은 동업자 몫 — S7은 DB를 변경하지 않았다.)

```sql
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null default 'android',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.device_tokens enable row level security;
-- 본인 토큰만 등록/조회/삭제
create policy device_tokens_self on public.device_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

## 3) Edge Function 배포 (`send-push`)
`EdgeFunctionPushSender._deployed = false` 라 발송을 건너뛴다.
- `supabase functions new send-push` → 입력 `{to_user_id, title, body, data}` 를 받아
  `device_tokens` 에서 대상 토큰을 조회하고 FCM(HTTP v1)로 전송.
- 배포 후 `_deployed = true`.
- 호출 인터페이스는 이미 `PushSenderPort.send()` 로 고정되어 있다(클라이언트 변경 불필요).

## 4) 발송 트리거 연결 (question_room)
`PushTrigger` 의 아래 메서드를 이벤트 성공 직후 호출한다(현재는 호출 지점만 준비):
- 멘토 답변 전송 성공 → `onMentorAnswered(studentUserId, threadId, threadTitle)`
- 학생 새 질문/메시지 → `onNewQuestionForMentor(mentorUserId, threadId, ...)`
- 멘토 새 메시지 → `onNewMessageForStudent(studentUserId, threadId, ...)`
> 상대방 user_id 는 방(mentor_student_rooms)의 student_id/mentor_id 로 구한다.

## 5) 딥링크(타깃) 실행 — S8 담당
S7은 **타깃 명세만** 정의했다: `PushPayload.data` = `{type, thread_id}`,
`PushTarget.fromData()` 가 `thread_id` → `PushTargetKind.questionThread` 로 매핑.
푸시 탭 시 이 타깃을 받아 **실제 화면 이동**은 S8(notifications/deeplink)이 수행한다.
(사용자에게 thread id 등 내부 경로는 노출하지 않는다.)

## 6) 마이페이지 재요청 연결 지점
권한 거부 후 재요청은 `PushService.instance.requestPermissionAgain(userId: ...)`.
마이페이지(S11) 설정에 "알림 다시 켜기" 항목을 추가해 이 함수를 호출하면 된다.
(S7은 `features/mypage/` 를 건드리지 않았다 — 연결만 문서화.)

## 실기기 검증(동업자)
Firebase 프로젝트 + 실제 Android 기기(에뮬레이터는 FCM 제한)에서
권한 팝업 → 토큰 발급 → device_tokens 등록 → 답변 이벤트 → 수신 → 탭 시 스레드 이동.
