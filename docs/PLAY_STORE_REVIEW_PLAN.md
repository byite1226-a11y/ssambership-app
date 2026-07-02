# Google Play 심사 통과 대비 — 리스크 분석 + 디벨롭 계획안

> 작성일: 2026-07-02 · 대상: `ssambership_app` v0.1.0+1 (pubspec.yaml:4)
> 관점: 구글플레이 심사관 시선으로 리포지토리를 점검하여, 한 번에 통과를 어렵게 만드는 요소를 유형별로 분석하고 수정방안·로드맵을 제시한다.
> 이 문서는 분석+계획이며, 코드 수정은 아래 Phase A~D로 진행한다.

---

## 요약 — 현재 상태 진단

**현재 상태로 제출 시 통과 가능성: 사실상 0% (P0 블로커 6건).**

- 기술적으로 **업로드 자체가 불가**하다(release가 debug 키 서명).
- 업로드가 되더라도 **정책 리젝이 확실**하다: 계정 삭제 수단 없음, 개인정보처리방침 미접근, 디지털 구독의 외부 결제 유도 설계, "보이지만 안 되는" 죽은 기능 다수.
- 반면 앱의 뼈대는 심사에 유리하다: 위험 권한 0개, 하드코딩 시크릿 없음, WebView 래퍼가 아닌 네이티브 구현, UGC 신고 기능 존재, admin 접근 차단. **P0/P1만 해소하면 통과 가능성이 높은 체질**이다.

| 등급 | 건수 | 성격 |
|------|------|------|
| 🔴 P0 | 6 | 즉시 리젝 또는 업로드 불가 |
| 🟠 P1 | 5 | 리젝/보류 가능성 높음 |
| 🟢 참고 | 6 | 긍정 요소 (감점 아님) |

---

## 🔴 P0 — 정책 블로커 (즉시 리젝 사유)

### P0-1. 계정 삭제 기능 전무

| 항목 | 내용 |
|------|------|
| 문제 유형 | **User Data 정책** — 계정 생성을 제공하는 앱은 계정 삭제 수단을 앱 내와 웹에서 모두 제공해야 함. Data safety 폼에도 삭제 요청 URL 기재가 필수. |
| 근거 | 레포 전체에 탈퇴/`deleteAccount` 코드 없음. `lib/features/mypage/ui/sections/settings_section.dart`는 로그아웃(:100)만 제공. |
| 리젝 사유 | 계정은 만들 수 있는데(웹 가입 + 앱 로그인) 지울 수 없음 → User Data 정책 위반 + Data safety 폼 작성 불가. |

**수정방안**
- **방안 A (권장)**: 마이페이지 설정 섹션에 탈퇴 플로우(경고 → 재확인 → 처리) + Supabase Edge Function으로 삭제 처리(auth.users 삭제 + 관련 데이터 정리·익명화). 공수: 중 (Edge Function + RLS 검토 포함 2~3일).
- 방안 B: 웹에 삭제 페이지를 만들고 앱은 링크 연결 + Play Console에 삭제 URL 등록. 공수: 소 (웹 페이지 별도).
- 방안 C: A+B 병행 — 인앱 진입점 + 웹 처리 페이지. 심사·사용자 모두에게 가장 안전. 공수: 중.

### P0-2. 개인정보처리방침·이용약관 미접근

| 항목 | 내용 |
|------|------|
| 문제 유형 | **Privacy Policy 필수 요건** — 스토어 등재 시 유효한 방침 URL 필수 + 앱 내 접근 요구. |
| 근거 | `lib/features/mypage/ui/sections/settings_section.dart:83-88` — '이용약관'·'개인정보 처리방침' 두 항목 모두 탭 시 "약관·개인정보는 웹에서 확인할 수 있어요. (준비 중)" 스낵바(:112)만 표시하는 스텁. |
| 리젝 사유 | 개인정보(이메일·닉네임·학년·이미지)를 수집하면서 방침 접근 수단이 없음. |

**수정방안**
- **방안 A (권장)**: 웹(`ssambership_web`)에 정책 페이지 게시 → 앱은 `url_launcher`로 연결 + Play Console에 URL 등록. 공수: 소 (웹 페이지 준비 시 앱은 반나절).
- 방안 B: 인앱 정적 화면으로 전문 내장. 공수: 소~중 (개정 시마다 앱 업데이트 필요한 단점).
- 방안 C: A+B — 링크 기본 + 오프라인 대비 내장 사본. 공수: 중.

### P0-3. 디지털 구독의 외부 결제 유도 설계

| 항목 | 내용 |
|------|------|
| 문제 유형 | **Payments 정책** — 디지털 재화·구독은 Google Play Billing 의무, 외부 결제로의 유도(스티어링) 금지. |
| 근거 | `lib/core/web_bridge/web_bridge_actions.dart` — 구독/캐시충전/빌링 버튼이 외부 브라우저의 웹 결제 페이지를 열도록 설계됨(`openSubscribeWeb`, `openRechargeWeb` 등). 현재는 `web_bridge_config.dart`의 `baseUrl = ''` 라 죽은 버튼이지만, 설계 의도 자체가 심사 대상. |
| 리젝 사유 | 디지털 구독 상품의 결제를 앱 밖(웹 토스페이먼츠)으로 유도 → Play Billing 우회. 한국은 대체결제 허용 국가지만 **신청·승인 절차와 병행 제공 요건**이 있어 무단 외부 유도는 동일하게 위반. |

**수정방안**
- **방안 A (권장, v0.1)**: 결제 진입점 제거·조회 전용화 — 구독 상태/캐시 잔액은 보여주되, 버튼·링크·가격 유도 없이 "웹에서 구독을 관리할 수 있어요" 수준의 **안내 문구만** 표시(링크 없음). 공수: 소 (1일).
- 방안 B: Google Play Billing(`in_app_purchase`) 도입 — 캐시 상품을 인앱 상품으로 등록. 공수: 대 (서버 영수증 검증 + 수수료 구조 재설계 필요).
- 방안 C: 한국 **대체결제(Alternative Billing) 프로그램** 신청 후 승인 범위 내에서 병행 제공. 공수: 대 (비즈니스 절차 + 구현, 승인까지 리드타임).

> 개별질문 등 **기충전 캐시를 앱 내에서 디지털 재화에 소비**하는 기능도 동일 정책의 검토 대상이다. 릴리즈 빌드에서 해당 진입점을 끌 수 있는 feature flag를 마련해 정책 결정 전까지 토글 가능하게 한다.

### P0-4. 죽은 기능 다수 — Broken Functionality / 최소 기능 정책

| 항목 | 내용 |
|------|------|
| 문제 유형 | **Broken Functionality·Minimum Functionality 정책** — 보이는데 동작하지 않는 UI는 리젝 사유. |
| 근거 | ① 회원가입 링크 스텁: `lib/features/auth/login_screen.dart:72-76` `_openWebSignUp()` → "(링크 준비 중)" 스낵바 ② 숏폼 재생 버튼이 재생 안 됨(비디오 플레이어 미구현) ③ 좋아요 초기상태 미로딩 ④ 결제·약관 버튼 스텁 — `docs/APP_FEATURE_STATUS.md`에 자체 인정된 목록 존재. |
| 리젝 사유 | 심사관이 몇 번만 탭해도 "준비 중" 스낵바를 연달아 만나게 됨. |

**수정방안**
- **방안 A (권장)**: 미구현 UI 숨김/제거 — 숏폼 재생 아이콘 제거(또는 상세를 이미지 뷰로 전환), 스텁 버튼 삭제, "준비 중" 노출 최소화. 공수: 소 (1~2일).
- 방안 B: 최소 구현 — `video_player` 도입, 가입은 인앱 가입 구현 또는 웹 가입 URL 연결. 공수: 중.
- 방안 C: 기능 플래그로 릴리즈 빌드에서만 비노출(디버그에선 유지). 공수: 소.

### P0-5. release가 debug 키로 서명

| 항목 | 내용 |
|------|------|
| 문제 유형 | **기술 블로커** — debug 서명 AAB는 Play Console 업로드 자체가 거부됨. |
| 근거 | `android/app/build.gradle.kts:32` — `signingConfig = signingConfigs.getByName("debug")` (":30 TODO 주석으로 자체 인지"). |

**수정방안**
- **방안 A (권장)**: upload keystore 생성 → `key.properties` 참조 서명 config 추가(파일은 gitignore) → Play App Signing 등록. 공수: 소 (반나절).
- 방안 B: CI 시크릿 주입 서명 — 로컬 키파일 없이 CI에서 base64 시크릿으로 서명. 공수: 소~중 (CI 구성 포함).

### P0-6. targetSdk/minSdk/versionCode 미고정

| 항목 | 내용 |
|------|------|
| 문제 유형 | **타깃 API 요건** — Play는 최신 안드로이드 타깃 API(현행 35) 이상을 요구. Flutter SDK 기본값 위임은 로컬 SDK 버전에 따라 달라져 미충족 위험. |
| 근거 | `android/app/build.gradle.kts:22-25` — `minSdk`/`targetSdk`/`versionCode`/`versionName` 모두 `flutter.*` 위임. |

**수정방안**
- **방안 A (권장)**: `build.gradle.kts`에 `targetSdk = 35` 등 명시 고정(+ minSdk 결정·문서화). 공수: 소 (1시간 + 회귀 확인).
- 방안 B: Flutter SDK 버전 핀 + CI에서 산출 AAB의 targetSdk 검증 스텝. 공수: 소~중.

---

## 🟠 P1 — 리젝/보류 가능성 높음

### P1-1. 기본 Flutter 런처 아이콘 + `android:label="ssambership_app"`
- 유형: 스토어 품질/브랜딩 (사칭·저품질 인상).
- 근거: `android/app/src/main/AndroidManifest.xml:3` — label이 패키지명 그대로. 런처 아이콘은 Flutter 기본.
- 방안 A(권장): `flutter_launcher_icons`로 브랜드 아이콘 + adaptive icon 일괄 생성. 방안 B: 수동 mipmap 교체. **공통**: label을 `쌤버십`으로 교체. 공수: 소.

### P1-2. UGC 신고는 있으나 사용자 차단 없음
- 유형: **UGC 정책** — 신고와 차단(또는 뮤트) 수단을 모두 기대.
- 근거: 신고는 구현됨(`lib/features/community/ui/widgets/report_sheet.dart` → `content_reports`). 차단 기능 없음.
- 방안 A: `user_blocks` 테이블 + 피드 조회 필터 (웹 레포 SQL 마이그레이션 필요 — 스키마는 웹 레포 소유 원칙). 방안 B: 클라이언트 로컬 mute. 방안 C(v1 방어): 신고 + 운영 삭제 프로세스 문서화로 대응. 공수: A 중 / B 소 / C 소.

### P1-3. 심사관이 로그인 불가
- 유형: 심사 진행 불가 → 보류·리젝.
- 근거: 인앱 가입 없음 + 가입 링크 스텁(P0-4 ①). 게스트 모드는 있으나 핵심 기능(질문방)은 로그인 필요.
- 방안 A(필수): Play Console **App access**에 테스트 계정(학생·멘토 각 1개) 제공. 방안 B: 게스트 둘러보기 범위 확대. 공수: A 소 / B 중.

### P1-4. INTERNET 권한이 debug/profile 매니페스트에만 존재
- 근거: `android/app/src/debug/AndroidManifest.xml:6`, `android/app/src/profile/AndroidManifest.xml:6`에만 선언, `main/AndroidManifest.xml`에는 없음 → release 빌드가 네트워크 불가로 **전 기능 마비**(Broken Functionality로 직결).
- 방안(단일): main 매니페스트에 `<uses-permission android:name="android.permission.INTERNET"/>` 1줄 추가. 공수: 극소.

### P1-5. Data safety 폼 대비 자료 없음
- 유형: Data safety 미제출/부실 기재 시 등재 불가 또는 사후 제재.
- 수집 항목 정리(현행 코드 기준): 이메일(로그인), 이름·닉네임·학년(프로필), UGC(질문/게시글/댓글), 이미지(질문 첨부·필기), 기기 정보(푸시 도입 시 토큰). 제3자 공유 없음, 판매 없음, 전송 암호화(HTTPS), 삭제 수단은 P0-1 완료 후 URL 기재.
- 방안: 위 표를 `docs/DATA_SAFETY_FORM.md`로 문서화 + 폼 항목별 응답 가이드 작성. 공수: 소.

---

## 🟢 참고 — 긍정 요소 (심사에 유리)

1. 하드코딩 시크릿 없음 — Supabase 키는 `.env` 주입(`lib/core/config/app_config.dart`), `.env` 미커밋.
2. dev 도구 release 제외 — `lib/features/dev/dev_flags.dart`로 릴리즈 빌드에서 차단.
3. 위험 권한 0개 — 카메라/위치/연락처 등 미사용 (이미지는 photo picker 경유).
4. WebView 래퍼 아님 — 전 화면 네이티브 Flutter 구현.
5. UGC 신고 기능 존재 — `content_reports` 연동 완료.
6. admin 앱 접근 차단 — 역할 게이트에서 관리자 로그인 차단(`lib/core/auth/`).

---

## 디벨롭 로드맵

### Phase A — 정책 블로커 해소 (P0-1~4)

| 작업 | 대상 파일 |
|------|-----------|
| 약관/방침 웹 링크 연결 (P0-2 방안 A) | `lib/features/mypage/ui/sections/settings_section.dart` (:83-88 스텁 교체), `lib/core/web_bridge/web_bridge_config.dart` (정책 URL 상수) |
| 계정 삭제 플로우 (P0-1 방안 C) | `settings_section.dart` (진입점), 신규 `lib/features/mypage/ui/screens/account_delete_screen.dart`, Supabase Edge Function `delete-account` (웹 레포 `supabase/functions/` — 스키마·함수는 웹 레포 소유) |
| 결제 진입점 조회 전용화 (P0-3 방안 A) | `lib/core/web_bridge/web_bridge_actions.dart`, `lib/features/mypage/` 구독/캐시 카드 (버튼 제거 → 안내 문구), `lib/features/mentors/` 상세의 구독 버튼 |
| 죽은 UI 정리 (P0-4 방안 A) | `lib/features/auth/login_screen.dart` (:72-76, :159 가입 스텁), 숏폼 재생 아이콘(`lib/features/community/ui/`), 좋아요 초기상태, `docs/APP_FEATURE_STATUS.md` 기준 전수 점검 |

### Phase B — 빌드/기술 (P0-5·6, P1-1·4)

| 작업 | 대상 파일 |
|------|-----------|
| 릴리즈 서명 config | `android/app/build.gradle.kts` (:26-34), 신규 `android/key.properties`(gitignore), `android/.gitignore` |
| targetSdk 35 등 명시 고정 | `android/app/build.gradle.kts` (:22-25) |
| INTERNET 권한 | `android/app/src/main/AndroidManifest.xml` |
| 앱명·아이콘 | `android/app/src/main/AndroidManifest.xml` (:3 label), `pubspec.yaml`(flutter_launcher_icons), `android/app/src/main/res/mipmap-*` |

### Phase C — UGC 보강 (P1-2)

| 작업 | 대상 파일 |
|------|-----------|
| 사용자 차단 | 웹 레포 `supabase/sql/NNN_user_blocks.sql`(테이블+RLS), 앱 `lib/features/community/data/`(차단 필터), 게시글/댓글 액션 시트에 차단 항목 |
| 운영 프로세스 문서화 | `docs/UGC_MODERATION_PROCESS.md` (신고 접수→검수→조치 SLA) |

### Phase D — 출시 준비 (P1-3·5)

| 작업 | 산출물 |
|------|-----------|
| Data safety 폼 | `docs/DATA_SAFETY_FORM.md` (수집 항목표 + 폼 응답 가이드) |
| 테스트 계정 | Play Console App access 등록용 학생·멘토 계정 (스테이징 데이터 시드 포함) |
| 스토어 등록정보 | 스크린샷·그래픽·설명문 체크리스트, 방침 URL·삭제 URL 등록 확인 |

**권장 순서**: B(서명·권한은 모든 테스트의 전제) → A → D → C. 단 P1-4(1줄)와 P0-6은 즉시 처리 가능.

---

## 부록 — 근거 파일 인덱스

| 인용 | 확인 내용 |
|------|-----------|
| `lib/features/mypage/ui/sections/settings_section.dart:83-88, :100, :112` | 약관/방침 항목·로그아웃·"준비 중" 스낵바 |
| `lib/features/auth/login_screen.dart:72-76, :159` | `_openWebSignUp()` 스텁과 호출 버튼 |
| `lib/core/web_bridge/web_bridge_config.dart` / `web_bridge_actions.dart` | `baseUrl = ''`, 외부 결제 유도 설계 |
| `android/app/build.gradle.kts:22-25, :32` | flutter.* 위임, debug 서명 |
| `android/app/src/main/AndroidManifest.xml:3` | `android:label="ssambership_app"`, INTERNET 부재 |
| `android/app/src/{debug,profile}/AndroidManifest.xml:6` | INTERNET이 dev 매니페스트에만 |
| `lib/features/community/ui/widgets/report_sheet.dart` | UGC 신고 구현 |
| `lib/features/dev/dev_flags.dart` | dev 도구 release 차단 |
| `docs/APP_FEATURE_STATUS.md` | 기능별 동작/스텁 자체 감사 |
| `pubspec.yaml:4` | `version: 0.1.0+1` |
