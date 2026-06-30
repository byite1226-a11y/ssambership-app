import 'package:flutter/material.dart';
import '../features/question_room/question_room_screen.dart';
import '../features/community/community_screen.dart';
import '../features/mentors/mentors_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/mypage/mypage_screen.dart';
import '../shared/constants/app_constants.dart';

/// 하단 탭 5개 셸(질문방·커뮤니티·멘토찾기·알림·마이페이지).
/// 각 탭은 '빈 화면'. role(student/mentor/admin) 분기 자리만 둔다.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // role 분기 자리: 멘토/관리자는 일부 탭 구성이 달라질 수 있음(후속에서 분기).
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppConstants.bottomTabLabels[_index])),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
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
