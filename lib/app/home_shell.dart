import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_service.dart';
import '../features/community/community_screen.dart';
import '../features/mentors/mentors_screen.dart';
import '../features/mypage/mypage_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/question_room/question_room_screen.dart';
import '../shared/constants/app_constants.dart';
import 'entry_guard.dart';

/// 하단 탭 5개 셸(질문방·커뮤니티·멘토찾기·알림·마이페이지).
///
/// 게스트(둘러보기)는 커뮤니티·멘토찾기만 접근 가능.
/// 질문방·알림·마이페이지를 누르면 "로그인이 필요해요" 안내와 함께 로그인 화면으로 보낸다.
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
    MyPageScreen(),
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.forum_outlined,
    Icons.groups_outlined,
    Icons.search_outlined,
    Icons.notifications_none,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();
    // 게스트는 접근 가능한 탭(멘토 찾기=2)에서 시작.
    _index = AuthService.instance.isGuest ? 2 : 0;
  }

  void _onSelect(int i) {
    if (AuthService.instance.isGuest && !EntryGuard.isTabAllowedForGuest(i)) {
      context.go('${EntryGuard.login}?notice=login_required');
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppConstants.bottomTabLabels[_index])),
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
