# iOS 빌드 & App Store 출시 가이드 (ssambership_app)

단일 Flutter 코드베이스이므로 **Android 와 동일한 기능·UI·UX·디자인**이 iOS 에서 그대로 동작한다.
별도 iOS 전용 코드 작성 불필요 — 아래 절차만 macOS 에서 수행하면 된다.

> 빌드/아카이브/업로드는 **macOS + Xcode** 에서만 가능하다(Linux/CI-only 환경 불가).

## 요구 사항
- macOS + Xcode 15 이상 (App Store 에서 설치)
- Flutter SDK 3.22 이상 (`flutter doctor` 로 확인)
- CocoaPods (`sudo gem install cocoapods` 또는 `brew install cocoapods`)
- 실기기 배포/출시 시: Apple Developer 계정 (유료 멤버십)

## 1회 셋업
```bash
git clone https://github.com/byite1226-a11y/ssambership-app.git
cd ssambership-app
cp .env.example .env        # 값 채우기 (아래 "사전 조건 ①" 참고)
flutter pub get
cd ios && pod install && cd ..
```

## 개발 중 실행
```bash
open -a Simulator            # iOS 시뮬레이터 실행
flutter run                  # 기기 선택 프롬프트에서 시뮬레이터 선택
```

- **시뮬레이터**: `.env` 의 `SUPABASE_URL=http://127.0.0.1:54321` 그대로 동작 (코드가 자동 분기).
- **실기기(개발)**: `.env` 의 `SUPABASE_URL_LAN` 에 Mac 의 LAN IP (`http://192.168.x.x:54321`) 입력.
  - Info.plist 에 `NSAllowsLocalNetworking` 이 설정돼 있어 로컬 http 통신이 허용된다 (원격 https 출시에는 영향 없음).

---

# App Store 출시

## 사전 조건 ① — `.env` 를 **원격 production 값**으로 채운다
`.env` 는 `pubspec.yaml` 이 **필수 asset** 으로 선언한다. 없으면 `flutter build` 가 즉시 실패한다.
```bash
cp .env.example .env
```
그리고 `.env` 안을 **운영 값**으로 채운다:
```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<remote-anon-key>
```

> ⚠️ **가장 흔한 실수:** `.env` 를 만들되 로컬 기본값(`http://127.0.0.1:54321`)을 그대로 두면,
> 릴리스 빌드는 **성공**하지만 App Store 에 올라간 앱은 localhost 를 바라봐 **아무 데이터도 못 불러온다**
> (앱은 crash 없이 "빈 앱"으로 뜬다 — `lib/main.dart` 의 graceful 처리). 반드시 원격 URL/anon key 로 교체할 것.
> `SUPABASE_URL` 이 `supabase.co` 를 포함하면 플랫폼 분기 없이 그대로 사용된다(`lib/core/config/app_config.dart`).

## 사전 조건 ② — 서명 팀 지정
1. `open ios/Runner.xcworkspace` (⚠️ `.xcodeproj` 아님)
2. Runner 타깃 → **Signing & Capabilities**
3. **Team** 선택(Apple Developer 계정), **"Automatically manage signing"** 체크
4. Bundle Identifier 확인: `com.ssambership.ssambershipApp`
   - App Store Connect 에 동일한 Bundle ID 로 **App ID / 앱 레코드**가 등록돼 있어야 한다.
5. (같은 화면에서) 좌측 파일 트리 Runner ▸ `PrivacyInfo.xcprivacy` 가 Runner 타깃의
   **Build Phases ▸ Copy Bundle Resources** 에 포함돼 있는지 확인(레포에 이미 배선돼 있음).

## 사전 조건 ③ — 버전 확인/증가
버전은 `pubspec.yaml` 의 `version: <name>+<build>` 가 지배한다
(→ `CFBundleShortVersionString` = name, `CFBundleVersion` = build).
```yaml
version: 0.1.0+1     # 예: 마케팅 버전 0.1.0, 빌드 번호 1
```
- **App Store Connect 재업로드 규칙:** 같은 마케팅 버전 안에서 **빌드 번호는 매 업로드마다 유일하게 증가**해야 한다.
  두 번째 업로드부터는 `+2`, `+3` … 으로 올리거나 빌드 시 지정한다:
  ```bash
  flutter build ipa --release --build-name=1.0.0 --build-number=2
  ```
- 첫 공개 출시라면 마케팅 버전을 `1.0.0` 으로 올릴지 결정한다(현재 `0.1.0` — 소프트런치 의도가 아니면 상향 권장).

## 빌드
```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release        # build/ios/ipa/*.ipa 생성 (+ Xcode archive)
```

## App Store Connect 업로드 (셋 중 하나)

**A) Xcode Organizer (GUI, 가장 무난)**
```bash
open ios/Runner.xcworkspace
```
Product ▸ Archive → Organizer 창에서 **Distribute App ▸ App Store Connect ▸ Upload**.

**B) `altool` CLI (자동화)**
```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
     --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```
- `--apiKey` = App Store Connect API **Key ID**, `--apiIssuer` = **Issuer ID**.
- API 키 파일(`AuthKey_<KEY_ID>.p8`)은 altool 이 찾는 경로에 둔다:
  `~/.appstoreconnect/private_keys/`, `~/.private_keys/`, 또는 실행 디렉터리의 `./private_keys/`.

**C) Transporter 앱** (Mac App Store 무료): `build/ios/ipa/*.ipa` 를 드래그해 업로드.

업로드 후 App Store Connect 의 빌드가 "처리 중"에서 완료되면 TestFlight/심사에 제출할 수 있다.

## App Store 심사 전 체크리스트
- [ ] **수출 규정(암호화):** `Info.plist` 에 `ITSAppUsesNonExemptEncryption=false` 설정됨(레포 반영).
      표준 HTTPS 만 사용하므로 면제 — 업로드마다 뜨던 질문이 사라진다. (비표준 암호화 추가 시 재검토)
- [ ] **개인정보 매니페스트:** `ios/Runner/PrivacyInfo.xcprivacy` 포함됨. 필수 사유 API(UserDefaults·FileTimestamp) 선언.
      Apple 이 특정 API 에 대해 **ITMS-91053** 메일을 보내면 해당 카테고리를 같은 형식으로 추가한다.
- [ ] **App Privacy(개인정보 라벨):** App Store Connect ▸ 앱 개인정보 설문을 실제 수집 항목에 맞춰 작성한다.
      이 앱은 Supabase 계정(이메일/사용자ID)과 사용자 콘텐츠(질문·첨부)를 다루며 **추적(ATT)은 없음**.
      작성한 값과 `PrivacyInfo.xcprivacy` 의 `NSPrivacyCollectedDataTypes` 를 일치시킨다.
- [ ] **Commerce-Zero 안내:** 앱 안에 결제/가격/구매 버튼이 **없다**(구독·충전은 `web_bridge` 로 웹만 연다).
      In-App Purchase 미탑재이므로, 심사 노트에 "결제는 외부 웹에서 처리, 앱은 읽기 중심" 임을 적어 오해를 줄인다.
- [ ] **스크린샷/메타데이터:** 필수 기기 크기 스크린샷과 설명·키워드·지원 URL·개인정보 처리방침 URL 등록.
- [ ] **아이콘:** 1024 App Store 아이콘은 alpha 없는 RGB(레포 반영). 로고 변경 시 `dart run flutter_launcher_icons` 재실행.

## 알려진 상태 / 후속 작업
- **푸시 알림**: 현재 골격만 존재하고 비활성 (`device_tokens` 테이블 미생성, `_tableExists=false`).
  활성화 시 firebase_messaging 도입 + Xcode 에서 Push Notifications capability 추가 필요 (HANDOFF.md 참고).
- **딥링크**: DeepLinkService 는 자리(placeholder). 활성화 시 Info.plist 에 CFBundleURLTypes / Associated Domains 추가.

## 트러블슈팅
- `flutter build` 즉시 실패(`No file or variants found for asset: .env`) → `.env` 미생성. 사전 조건 ① 수행.
- `pod install` 실패 → `cd ios && pod repo update && pod install`.
- 서명 오류 → Xcode 에서 Team 미선택 상태. "Automatically manage signing" 체크.
- 업로드 시 수출 규정 질문 반복 → `ITSAppUsesNonExemptEncryption` 키 확인(위 체크리스트).
- 재업로드 거부(빌드 번호 중복) → 사전 조건 ③ 의 `--build-number` 증가.
- App Store 앱이 빈 화면/데이터 없음 → `.env` 가 원격이 아닌 localhost 값. 사전 조건 ① 재확인.
