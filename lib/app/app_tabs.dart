import 'package:flutter/foundation.dart';

/// 하단 탭 인덱스(딥링크·탭 전환 공용 상수).
///
/// 개편(개별질문 승격): 마이페이지는 하단 탭에서 빠지고 우측 상단 프로필
/// 아이콘(push)으로 이동. 그 자리에 개별질문이 동일 위상 탭으로 들어온다.
class AppTab {
  AppTab._();

  static const int questionRoom = 0;
  static const int community = 1;
  static const int mentors = 2;
  static const int notifications = 3;
  static const int individualQuestion = 4;

  /// 가상 목적지: 하단 탭이 아닌 '우측 상단 프로필' 마이페이지(push 라우트).
  /// TabNavigator.go(AppTab.myPage) 요청 시 HomeShell 이 탭 전환 대신
  /// 마이페이지 화면을 push 한다(알림 딥링크 등 기존 호출부 호환 유지).
  static const int myPage = 100;
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
