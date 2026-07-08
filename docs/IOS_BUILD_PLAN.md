# iOS 빌드·App Store 제출 계획 (S20)

> 작성일: 2026-07-08 · 대상: `ssambership_app` v0.1.0+1
> `docs/PLAY_STORE_REVIEW_PLAN.md`(Android)의 iOS 대응 문서. Play 문서에서 이미 해소된 공통 항목(약관·개인정보·탈퇴·차단·가격표시 제거 등)은 iOS 에도 그대로 유효하므로 반복하지 않고, **iOS 고유 항목만** 다룬다.
> ⚠️ iOS 빌드는 **macOS + Xcode 에서만** 가능하다. 이 세션(S20, Linux 컨테이너)은 빌드 실행 없이 **설정 정합·심사 리스크 정리**까지를 범위로 한다.

---

## 1. S20 에서 반영한 것 (이 저장소 커밋)

| 항목 | 파일 | 내용 | 심각도 |
|---|---|---|---|
| 웹 브릿지 iOS 침묵 실패 | `ios/Runner/Info.plist` | `LSApplicationQueriesSchemes`(https·http) 추가. `web_bridge.dart:25` 가 `canLaunchUrl` 을 쓰는데 iOS 는 조회 대상 스킴을 plist 에 선언해야 true — 없으면 **약관·개인정보·지원·리뷰·탈퇴·정산 등 웹 링크 전 경로가 iOS 에서 조용히 실패**(안드로이드는 정상이라 발견 어려움) | **P0** |
| Podfile 부재 | `ios/Podfile` | 표준 Flutter Podfile 신설, `platform :ios, '13.0'` 명시(pbxproj `IPHONEOS_DEPLOYMENT_TARGET=13.0`·supabase_flutter 최소 요건과 일치). 이 프로젝트는 SwiftPM 병행 템플릿이라 CocoaPods 전용 플러그인(pdfx 등)이 있을 때 함께 쓰인다 | P1 |
| 프라이버시 매니페스트 부재 | `ios/Runner/PrivacyInfo.xcprivacy` + `project.pbxproj` 배선(Resources) | Apple 필수(2024.5~) 앱 프라이버시 매니페스트 — Flutter 표준 템플릿과 동일 내용(추적 없음·수집 없음·엔진 required-reason API 2종). 플러그인들은 각자 매니페스트 동봉 | P1 |
| 홈 화면 표시명 | `ios/Runner/Info.plist` `CFBundleDisplayName` | "Ssambership App" → **쌤버십** (Android 라벨·스토어 등록명과 일치 — Play P1-1 의 iOS 미러) | P1 |
| 수출규정 문답 생략 | `ios/Runner/Info.plist` `ITSAppUsesNonExemptEncryption=false` | 표준 HTTPS 암호화만 사용(면제 대상) — 업로드마다 나오는 export compliance 질문을 빌드 설정으로 선답 | P2 |

### 확인만 하고 손대지 않은 것 (이미 정상)
- **사진·카메라 권한 문구**: `NSPhotoLibraryUsageDescription`·`NSCameraUsageDescription` 한글 문구 기재됨(없으면 런타임 크래시 — 기존에 이미 대비).
- **file_picker(파일)·pdfx(PDF)**: iOS 는 문서 선택기(UIDocumentPicker) 방식이라 **추가 plist 권한 불필요**.
- **배포 타깃 13.0 / 디바이스 패밀리 iPhone+iPad**(`TARGETED_DEVICE_FAMILY = "1,2"`): 유지 — 필기 시리즈(S13~S19) 스타일러스 QA 가 iPad 대상이므로 iPad 지원 유지가 맞다.
- **런처 아이콘**: `flutter_launcher_icons` 가 `remove_alpha_ios: true` + 흰 배경으로 iOS 세트 생성 완료(alpha 있으면 App Store 업로드 거부 — 이미 대비).
- **ATS(App Transport Security) 예외 불필요**: ATS 는 도메인명 접속에만 적용되고 **IP 주소(127.0.0.1·LAN IP)는 예외**라, 로컬 Supabase(http) 개발에 plist 예외가 필요 없다. 운영은 https(`*.supabase.co`)라 무관.

---

## 2. 결정 필요 (오너) — 번들 ID

- 현재 값: `com.ssambership.ssambershipApp` (`project.pbxproj`, 3개 구성 동일).
- Android 는 `com.ssambership.ssambership_app` 인데 **iOS 번들 ID 에는 밑줄(_)을 쓸 수 없어** 그대로 맞출 수 없다(영숫자·하이픈·점만 허용).
- HANDOFF §3-6 권장은 `com.ssambership.app`. 어느 쪽이든 동작 차이는 없으나 **App Store Connect 에 첫 업로드 후에는 변경 불가**이므로, 업로드 전에 확정할 것. (현행 유지 시 아무 작업 불필요·변경 시 pbxproj 의 `PRODUCT_BUNDLE_IDENTIFIER` 3곳 + RunnerTests 3곳 수정.)

---

## 3. macOS 에서의 빌드 절차

```bash
# 0) 선행: .env 생성 — 에셋으로 번들되므로 없으면 빌드 자체가 실패한다.
#    (pubspec.yaml assets 에 .env 포함. 출시 빌드는 원격 production 값 — .env.example 참고)
cp .env.example .env   # 그리고 값 채우기

# 1) 의존성
flutter pub get

# 2) 시뮬레이터 스모크(서명 불필요)
flutter run -d <ios-simulator>

# 3) 릴리즈 빌드 — 스토어 제출용은 dart-define 아무것도 주입하지 않는다
#    (= IQ 작성 off + 구독 관리 링크 off + 운영 도메인, Android 와 동일 규약 HANDOFF §3-1-B)
flutter build ipa        # Xcode 서명 구성 후. 산출물 build/ios/ipa/*.ipa
# 서명 전 검증만 하려면: flutter build ios --release --no-codesign
```

- CocoaPods 필요(`sudo gem install cocoapods` 또는 brew). `pod install` 은 flutter 도구가 자동 실행.
- 버전 규약은 Android 와 공유: `pubspec.yaml` `version: x.y.z+N` — **업로드마다 +N 증가**(`CFBundleVersion` = `FLUTTER_BUILD_NUMBER`), 같은 빌드번호 재업로드는 App Store Connect 가 거부.
- 실기기 QA 항목·계정 준비는 `docs/MANUAL_QA_RUN_2026-07.md` 시트를 그대로 사용(iPad 스타일러스·PDF 렌더 포함).

---

## 4. 사람이 해야 하는 것 (코드 밖 — 제출 전 필수)

1. **Apple Developer Program 가입**(연 $99, 조직 또는 개인) → Xcode 에서 팀 로그인(서명은 `CODE_SIGN_STYLE = Automatic` 이라 인증서·프로비저닝 자동).
2. **번들 ID 확정**(§2) → App Store Connect 에서 앱 생성(이름 '쌤버십', 기본 언어 ko).
3. **App Privacy 폼**: Play Data safety(P1-5, `docs/DATA_SAFETY_FORM.md` 예정)와 같은 수집 항목표로 작성 — 계정정보(이메일)·사용자 콘텐츠(질문·이미지) 수집, 추적 없음.
4. **심사관용 데모 계정**: Play P1-3 과 동일 — 학생·멘토 각 1개(로그인 가능 + 구독·질문 데이터 시드)를 App Review 정보의 로그인 정보란에 기재. 인앱 가입이 없으므로 **리뷰 노트에 '계정은 웹에서 생성되는 서비스'임을 명시**할 것.
5. **스크린샷**(6.7"·6.5"·5.5" + iPad 13") · 지원 URL(`/support`) · 개인정보처리방침 URL(`/legal/privacy`) 등록.
6. **TestFlight 내부 테스트** 1회 이상 → 제출.

---

## 5. Apple 심사 리스크 (Play 재판정의 iOS 시각 재평가)

Apple 은 Google 보다 **외부 결제 유도(가이드라인 3.1.1/3.1.3)에 더 엄격**하다 — Play 문서의 P0-3 판정을 그대로 가져오면 안 되는 지점.

| 노출면 (스토어 빌드 기준) | Play 판정 | **Apple 시각** |
|---|---|---|
| 구매·구독 유도 진입점 | 0 (死배선) | ✅ 동일 — Commerce-Zero 그대로 유효. `openSubscribeWeb`/`openRechargeWeb` 호출부 없음 유지 |
| '구독 관리 (웹)' 링크 | 옵션1로 스토어 빌드 숨김 | ✅ 숨김 유지가 정답 — Apple 은 구독 관리 외부 링크도 3.1.1 로 볼 수 있어 **iOS 에서 켜지 말 것**(`SUBS_MANAGE_LINK_ENABLED` 주입 금지) |
| '정산 관리 (웹)' 링크(멘토) | 유지(정책 대상 아님) | ⚖️ 대체로 허용(멘토=판매자 지급 관리, 소비자 결제 아님) — 다만 심사관 오해 소지 있으니 리뷰 노트에 성격 설명 권장 |
| 회원 탈퇴 → 웹 열기 | 콘솔에 URL 등록 | ✅ 5.1.1(v) 계정 삭제: **인앱 가입이 없는 앱은 웹 링크 방식 허용** — 현재 구현(확인 다이얼로그 → `/account/delete`)으로 충족 |
| 게스트 열람(커뮤니티·멘토찾기) | — | ✅ 5.1.1 '기능 사용 전 강제 가입 금지' 요건에 오히려 유리 |
| 최소 기능(4.2) | — | ✅ 네이티브 화면·필기·첨부 등 실기능 다수 — 웹뷰 껍데기 아님 |

**요약**: 코드 쪽 잔여 리스크는 없음. 제출 게이트는 전부 §4(사람 작업)와 웹 레포 소유 항목(약관·개인정보·탈퇴 페이지 실게시 — Play 문서와 공유).

---

## 6. 남은 것 (후속 세션 후보)

- **(선택) 푸시(S7 골격) iOS 활성화**: APNs 키 발급 + Firebase iOS 앱 등록(`GoogleService-Info.plist` — gitignore 됨) + Xcode Push Notifications capability. Android 푸시 활성화와 같은 묶음으로 진행 권장(HANDOFF §3-4).
- **(선택) 웹→앱 복귀 딥링크**: 앱 스킴/Universal Links — HANDOFF §3-1 의 보류 항목, iOS 는 Associated Domains 필요.
- **macOS 실빌드 검증**: 본 문서 §3 절차 1회 완주(시뮬레이터 스모크 → `--no-codesign` 빌드)가 첫 후속 작업.
