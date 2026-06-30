/// 앱 전역 상수. 미확정 값은 '키만' 두고 값은 비운다(하드코딩 금지).
library;

class AppConstants {
  AppConstants._();

  /// 멘토 정산일 — 매월 23일 (확정값).
  static const int mentorPayoutDayOfMonth = 23;

  /// 앱 표시명 (브랜드).
  static const String appDisplayName = '쌤버십';

  /// 하단 탭 (학생 기준 5개). 영문 코드는 노출하지 않으며 라벨만 화면에 쓴다.
  static const List<String> bottomTabLabels = <String>[
    '질문방',
    '커뮤니티',
    '멘토 찾기',
    '알림',
    '마이페이지',
  ];
}
