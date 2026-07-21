# 푸시 알림 — 수신·토큰 등록 전용 (상태: WAITING_EXTERNAL_FIREBASE_CONFIG)

이 디렉터리(`lib/core/push/`)는 **푸시 '수신'과 '디바이스 토큰 수명주기'만** 담당한다.

> **발송은 서버 outbox worker 단독**(`record_domain_notification` → `notification_outbox`
> → deliveries). **앱은 수신·토큰 등록만 담당한다** — FCM HTTP 호출·Edge Function
> invoke 등 클라이언트 발송 경로는 **제거됐고 다시 만들지 말 것**
> (과거 `push_trigger.dart`/`edge_function_push_sender.dart` 는 2026-07-21 삭제).

## 현재 상태: WAITING_EXTERNAL_FIREBASE_CONFIG

코드는 완성돼 있고 `firebase_core`/`firebase_messaging` 의존성도 pubspec 에 있다.
다만 **Firebase 설정 파일이 저장소에 없어**(날조·커밋 금지) `FirebasePushGateway.initialize()`
의 `Firebase.initializeApp()` 이 실패하고, **준비 경계(ready=false)** 뒤에서 푸시만
조용히 비활성화된 채 앱이 정상 구동한다(크래시 없음, 디버그 로그 1줄).

### 활성화 절차(외부 작업 — 이 순서 그대로)
1. Firebase 콘솔에서 Android/iOS 앱 등록(패키지/번들 `com.ssambership.app`).
2. **Android**: `android/app/google-services.json` 배치 +
   `android/app/build.gradle.kts` 의 `plugins { ... }` 에
   `id("com.google.gms.google-services")` 추가(루트 settings.gradle.kts 에 플러그인
   버전 선언 포함). ※ json 없이 플러그인만 먼저 넣으면 빌드가 깨지므로 **지금은
   의도적으로 미적용** 상태다.
3. **iOS(macOS 필요)**: `ios/Runner/GoogleService-Info.plist` 를 Xcode 로 Runner 타깃에
   추가 → Signing & Capabilities 에서 **Push Notifications** 활성화
   (`aps-environment` entitlement 자동 생성 — entitlements 파일을 손으로 날조하지 말 것)
   → APNs 인증 키(.p8)를 Firebase 콘솔 Cloud Messaging 에 등록 → `pod install`.
4. 실기기에서 확인: 권한 팝업 → 토큰 등록(`device_tokens` 행) → 서버 발송 → 수신 →
   탭 시 해당 탭 이동. (에뮬레이터는 FCM 제한. 이 저장소 CI 환경은 dl.google.com 차단으로
   gradle 빌드 불가 — 빌드는 CI/로컬에서.)

설정 파일이 놓이면 **코드 수정 없이** 게이트웨이가 ready=true 로 살아난다.

## 구조 (포트 + 수동 fake, DI 프레임워크 없음)

| 파일 | 역할 |
|---|---|
| `push_ports.dart` | 추상 경계: `PushPermissionPort`/`PushPermissionStatus`(설정 화면이 import — **이름·API 유지**), `PushGatewayPort`, `DeviceTokenRegistrarPort` |
| `firebase_push_gateway.dart` | `FirebasePushGateway`(준비 경계 + FCM 스트림/토큰), `FirebasePushPermission`(권한 매핑), top-level `firebasePushBackgroundHandler`(`@pragma('vm:entry-point')`, no-op 안전) |
| `push_payload.dart` | 수신 payload 파싱 — `type` 은 정본 17종(`notification_types.dart`) 정확 일치, id(room/thread/question) + dedup 키(notification_id/event_key). **link/url 필드는 버린다** |
| `device_token_registrar.dart` | 서버 계약 구현(아래) |
| `push_service.dart` | 오케스트레이션: 수신 스트림 노출 + 토큰 수명주기 + 권한 요청 API |

딥링크 소비는 `lib/core/deeplink/`(`NotificationDeepLinkController` 순수 로직 +
`DeepLinkService` 배선). 허용 목적지는 `notificationDestinationOf` 의 탭뿐 —
payload 로 URL/외부 scheme 을 실행하지 않는다.

## 서버 계약 (스테이징 검증 2026-07-21 — 정본)

- **등록**: RPC `register_device_token(p_token text, p_platform text)` → jsonb
  `{ok, device_token_id}`. SECURITY DEFINER. `ON CONFLICT(token)` 시 현재 `auth.uid()`
  로 **원자적 재소유 + revoked_at 해제** → **계정 전환은 새 로그인 후 재등록만으로 끝**.
  platform 은 `ios|android|web`(그 외 서버가 'unknown' 저장). 오류: AUTH_REQUIRED/TOKEN_REQUIRED.
- **철회**: `revoke_device_token` RPC 는 **authenticated EXECUTE 권한이 없다 — 호출 금지**.
  대신 본인 행 직접 UPDATE(RLS `device_tokens_modify_own`):
  `UPDATE device_tokens SET revoked_at=now(), updated_at=now() WHERE token=<token> AND user_id=auth.uid()`.
  **반드시 `auth.signOut()` '이전'**(세션 유효 시점)에 — `AuthService.signOut()` 이
  `PushService.revokeBeforeSignOut()` 를 먼저 await 하도록 이미 배선됨(실패해도
  로그아웃 비차단).
- **수신 data 계약**: `type`(17종 코드) + 선택 `room_id`/`thread_id`/`question_id` +
  dedup 용 `notification_id`/`event_key`.

## 지뢰(하지 말 것)

- 앱에서 푸시 **발송** 경로 복원 금지(위 원칙).
- `google-services.json`/`GoogleService-Info.plist`/entitlements **날조·커밋 금지**.
- 토큰 문자열·device_token_id 를 **로그/화면/스냅샷에 남기지 말 것**.
- `permission_handler` 추가 금지 — '영구 거부' 구분은 firebase_messaging 만으로는
  제한적(Android 13+ 2회 거부 후에도 API 는 denied 만 반환)임을 수용하고,
  재요청 UI 는 '설정에서 켜기' 안내로 폴백한다.
- `PushPermissionPort`/`PushPermissionStatus` 시그니처 변경 금지(설정 라인이 import).

## 테스트

`test/push/`(수명주기·권한·준비 경계·수신 스트림) + `test/deeplink/`(목적지 매핑·
dedup·pending TTL·계정 전환·외부 링크 무시) — 전부 수동 fake, 실제 Firebase 미접촉.
