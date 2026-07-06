import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_service.dart';
import '../features/community/community_screen.dart';
import '../features/individual_question/individual_question_tab_screen.dart';
import '../features/mentors/mentors_screen.dart';
import '../features/mypage/mypage_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/question_room/question_room_screen.dart';
import '../shared/constants/app_constants.dart';
import 'app_tabs.dart';
import 'entry_guard.dart';

/// 하단 탭 5개 셸(질문방·커뮤니티·멘토찾기·알림·개별질문).
///
/// 마이페이지는 하단 탭이 아니라 AppBar 우측 상단의 '원형 프로필' 버튼으로
/// 진입한다(push). 개별질문이 그 자리를 이어받아 다른 기능과 동일 위상이 된다.
///
/// 게스트(둘러보기)는 커뮤니티·멘토찾기만 접근 가능.
/// 질문방·알림·개별질문·마이페이지를 누르면 "로그인이 필요해요" 안내와 함께
/// 로그인 화면으로 보낸다.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  static const List<Widget> _pages = <Widget>[
    QuestionRoomScreen(),
    CommunityScreen(),
    MentorsScreen(),
    NotificationsScreen(),
    IndividualQuestionTabScreen(),
  ];

  // 아이콘 통일: Material Symbols rounded 한 세트(하단 탭·검색·액션 혼용 제거).
  static const List<IconData> _icons = <IconData>[
    Icons.forum_rounded,
    Icons.groups_rounded,
    Icons.search_rounded,
    Icons.notifications_rounded,
    Icons.question_answer_rounded,
  ];

  @override
  void initState() {
    super.initState();
    // 게스트는 접근 가능한 탭(멘토 찾기=2)에서 시작.
    _index = AuthService.instance.isGuest ? 2 : 0;
    // 알림 딥링크 등 앱 내 탭 전환 요청 수신.
    TabNavigator.request.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    TabNavigator.request.removeListener(_onTabRequest);
    super.dispose();
  }

  /// 탭 전환 요청 처리(딥링크). 처리 후 -1 로 되돌려 같은 탭 재요청도 감지.
  /// AppTab.myPage(가상 목적지)는 탭 전환이 아니라 마이페이지 push 로 처리.
  void _onTabRequest() {
    final int i = TabNavigator.request.value;
    if (i < 0) return;
    if (i == AppTab.myPage) {
      _openMyPage();
    } else {
      _onSelect(i);
    }
    TabNavigator.request.value = -1;
  }

  void _onSelect(int i) {
    if (AuthService.instance.isGuest && !EntryGuard.isTabAllowedForGuest(i)) {
      context.go('${EntryGuard.login}?notice=login_required');
      return;
    }
    setState(() => _index = i);
  }

  /// 우측 상단 프로필(원형) → 마이페이지 push. 게스트는 로그인 안내로 보낸다.
  void _openMyPage() {
    if (AuthService.instance.isGuest) {
      context.go('${EntryGuard.login}?notice=login_required');
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const _MyPagePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.bottomTabLabels[_index]),
        actions: <Widget>[
          // 마이페이지 진입점: 원형 도형 속 프로필(person) 아이콘.
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ProfileCircleButton(onTap: _openMyPage),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onSelect,
        destinations: <NavigationDestination>[
          for (int i = 0; i < _pages.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              label: AppConstants.bottomTabLabels[i],
            ),
        ],
      ),
    );
  }
}

/// 원형 배경 + 프로필 실루엣 아이콘(우측 상단 마이페이지 진입 버튼).
/// ★ 사진 placeholder 를 쓰지 않고 중립 원형 + person 아이콘으로 통일
///   (InitialAvatar 규약과 동일한 '깨진 이미지 금지' 원칙).
class _ProfileCircleButton extends StatelessWidget {
  const _ProfileCircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: AppConstants.myPageTitle,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_rounded, size: 22, color: scheme.primary),
        ),
      ),
    );
  }
}

/// 마이페이지 push 라우트 래퍼.
/// MyPageScreen 은 본문만 그리므로(자체 Scaffold 없음) 여기서 AppBar 를 씌운다.
class _MyPagePage extends StatelessWidget {
  const _MyPagePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.myPageTitle)),
      body: const MyPageScreen(),
    );
  }
}
