# Android 빌드 가이드 (ssambership_app)

단일 Flutter 코드베이스 — iOS 와 동일한 기능·UI·UX·디자인. 상세 원칙은 README·HANDOFF.md 참고.

## 요구 사항
- Flutter SDK 3.22 이상 (`flutter doctor` 로 Android toolchain ✓ 확인)
- Android Studio (SDK 36 + 에뮬레이터) — JDK 17 은 Android Studio 내장 사용 가능
- gradlew 스크립트는 커밋되지 않음(.gitignore) — Flutter 도구가 자동 생성/관리하므로 별도 조치 불필요

## 1회 셋업
```bash
git clone https://github.com/byite1226-a11y/ssambership-app.git
cd ssambership-app
cp .env.example .env        # SUPABASE_ANON_KEY 등 값 채우기 (README 참고)
flutter pub get
```

## 실행
```bash
flutter emulators --launch <에뮬레이터ID>   # 또는 Android Studio 에서 AVD 실행
flutter run
```

- **에뮬레이터**: `.env` 의 `SUPABASE_URL=http://127.0.0.1:54321` 그대로 두면 코드가
  자동으로 `10.0.2.2` 로 변환한다 (`lib/core/config/app_config.dart`).
- **실기기(개발)**: `.env` 의 `SUPABASE_URL_LAN` 에 PC 의 LAN IP (`http://192.168.x.x:54321`) 입력.
- 로컬 http 통신은 **debug/profile 빌드에서만** 허용된다
  (`android/app/src/debug|profile/AndroidManifest.xml` 의 `usesCleartextTraffic`).
  release 는 cleartext 차단 유지 → 출시는 반드시 원격 `https://<ref>.supabase.co` 사용.

## 릴리즈 서명
1. keystore 생성(1회, 절대 커밋 금지):
   ```bash
   keytool -genkey -v -keystore ~/ssambership-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ssambership
   ```
2. `android/key.properties.example` → `android/key.properties` 복사 후 값 입력
   (storeFile 경로·비밀번호·alias). `.gitignore` 가 커밋을 차단한다.
3. key.properties 가 없으면 release 산출물(`flutter build appbundle`/`apk`) 빌드가
   **즉시 실패**한다 — debug 서명 AAB 가 실수로 Play 에 첫 업로드돼 잘못된 업로드 인증서가
   등록되는 사고를 원천 차단한다.
   - CI 파이프라인 검증처럼 debug 서명 폴백이 **의도된** 경우에만
     `-PallowInsecureSigning=true` (또는 env `ORG_GRADLE_PROJECT_allowInsecureSigning=true`)
     로 빌드한다. 이 산출물은 스토어 제출 불가(NOT-for-submission).

## 출시 빌드
```bash
flutter build appbundle     # Play Store 업로드용 .aab → build/app/outputs/bundle/release/
flutter build apk           # 직접 배포용 .apk (필요 시)
```
- 업로드마다 `pubspec.yaml` 의 `version: x.y.z+N` 에서 **+N(versionCode) 반드시 증가**.
  (첫 내부 테스트 업로드는 `0.1.0+1` 그대로 사용 가능.)
- targetSdk 36 고정 — Google Play 2026-08-31 신규 앱 요건 충족.
- 업로드 전 **서명 인증서 확인**(debug 아님):
  ```bash
  keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
  ```
  출력의 인증서 소유자에 `CN=Android Debug` 가 **없어야** 한다. 있으면 key.properties
  없이(또는 `-PallowInsecureSigning=true` 로) 빌드된 것 — 업로드 금지, release 키로 재빌드.

## 알려진 상태 / 후속 작업
- **푸시 알림**: 골격만 존재·비활성 (`device_tokens` 테이블 미생성). 활성화 시
  firebase_messaging 도입 + `google-services.json` 추가 + POST_NOTIFICATIONS 권한(API 33+) 필요.
- **딥링크**: placeholder. 활성화 시 intent-filter(App Links) 추가.

## 트러블슈팅
- 에뮬레이터에서 Supabase 연결 안 됨 → 로컬 Supabase 실행 여부 확인 (`npx supabase status`)
- Gradle 메모리 오류 → `android/gradle.properties` 의 `-Xmx8G` 를 PC 사양에 맞게 하향
- 서명 오류 `keystore not found` → key.properties 의 storeFile 을 절대경로로 입력
