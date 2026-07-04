/// 앱 전역 상수. 미확정 값은 '키만' 두고 값은 비운다(하드코딩 금지).
library;

class AppConstants {
  AppConstants._();

  /// 멘토 정산일 — 매월 23일 (확정값).
  static const int mentorPayoutDayOfMonth = 23;

  /// 앱 표시명 (브랜드).
  static const String appDisplayName = '쌤버십';

  /// 확정 앱 로고 에셋(파란 사각 + 졸업모자). 로그인 헤더·스플래시 등 인앱 브랜드 마크.
  static const String brandLogoAsset = 'assets/branding/ssambership_logo_1024.png';

  /// 앱 표시 버전(마이페이지 설정 표기용). pubspec version 과 맞춘다.
  /// TODO: package_info_plus 도입 시 런타임 값으로 대체(현재는 표시 전용 상수).
  static const String appVersion = '0.1.0';

  /// 하단 탭 (학생 기준 5개). 영문 코드는 노출하지 않으며 라벨만 화면에 쓴다.
  static const List<String> bottomTabLabels = <String>[
    '질문방',
    '커뮤니티',
    '멘토 찾기',
    '알림',
    '마이페이지',
  ];
}
