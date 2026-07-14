# iOS 빌드 가이드 (ssambership_app)

단일 Flutter 코드베이스이므로 **Android 와 동일한 기능·UI·UX·디자인**이 iOS 에서 그대로 동작한다.
별도 iOS 전용 코드 작성 불필요 — 아래 절차만 macOS 에서 수행하면 된다.

## 요구 사항
- macOS + Xcode 15 이상 (App Store 에서 설치)
- Flutter SDK 3.22 이상 (`flutter doctor` 로 확인)
- CocoaPods (`sudo gem install cocoapods` 또는 `brew install cocoapods`)
- 실기기 배포/출시 시: Apple Developer 계정

## 1회 셋업
```bash
git clone https://github.com/byite1226-a11y/ssambership-app.git
cd ssambership-app
cp .env.example .env        # SUPABASE_ANON_KEY 등 값 채우기 (README 참고)
flutter pub get
cd ios && pod install && cd ..
```

## 실행
```bash
open -a Simulator            # iOS 시뮬레이터 실행
flutter run                  # 기기 선택 프롬프트에서 시뮬레이터 선택
```

- **시뮬레이터**: `.env` 의 `SUPABASE_URL=http://127.0.0.1:54321` 그대로 동작 (코드가 자동 분기).
- **실기기(개발)**: `.env` 의 `SUPABASE_URL_LAN` 에 Mac 의 LAN IP (`http://192.168.x.x:54321`) 입력.
  - Info.plist 에 `NSAllowsLocalNetworking` 이 설정돼 있어 로컬 http 통신이 허용된다 (원격 https 출시에는 영향 없음).
- **출시**: `.env` 를 원격 production 값(`https://<ref>.supabase.co`)으로 교체.

## 서명 (실기기/출시)
1. `open ios/Runner.xcworkspace` (⚠️ .xcodeproj 아님)
2. Runner 타깃 → Signing & Capabilities → Team 선택
3. Bundle Identifier: `com.ssambership.app` (Apple Developer 에 App ID 등록)

## 출시 빌드
```bash
flutter build ipa            # build/ios/archive → Xcode Organizer 로 업로드
```

## 알려진 상태 / 후속 작업
- **푸시 알림**: 현재 골격만 존재하고 비활성 (`device_tokens` 테이블 미생성, `_tableExists=false`).
  활성화 시 firebase_messaging 도입 + Xcode 에서 Push Notifications capability 추가 필요 (HANDOFF.md 참고).
- **딥링크**: DeepLinkService 는 자리(placeholder). 활성화 시 Info.plist 에 CFBundleURLTypes / Associated Domains 추가.
- **아이콘**: iOS AppIcon 은 이미 생성돼 커밋됨. 로고 변경 시 `dart run flutter_launcher_icons` 재실행.

## 트러블슈팅
- `pod install` 실패 → `cd ios && pod repo update && pod install`
- 시뮬레이터에서 Supabase 연결 안 됨 → 로컬 Supabase 가 떠 있는지 확인 (`npx supabase status`)
- 서명 오류 → Xcode 에서 Team 미선택 상태. Automatically manage signing 체크.
