import 'package:flutter/foundation.dart';

/// 하단 탭 인덱스(딥링크·탭 전환 공용 상수).
class AppTab {
  AppTab._();

  static const int questionRoom = 0;
  static const int community = 1;
  static const int mentors = 2;
  static const int notifications = 3;
  static const int myPage = 4;
}

/// 앱 내 탭 전환 요청 채널.
///
/// 알림 딥링크 등에서 [go] 로 탭 인덱스를 요청하면 HomeShell 이 수신해 전환한다.
/// 화면 간 직접 결합 없이(전역 채널) 탭 이동을 처리 — HomeShell 탭 상태를 노출하지 않아도 된다.
class TabNavigator {
  TabNavigator._();

  /// -1 = 대기(요청 없음). HomeShell 이 처리 후 -1 로 되돌린다.
  static final ValueNotifier<int> request = ValueNotifier<int>(-1);

  static void go(int tabIndex) => request.value = tabIndex;
}
