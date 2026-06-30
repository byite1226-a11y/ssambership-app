import 'package:flutter/material.dart';
import '../../design/widgets/empty_screen.dart';

/// 마이페이지(빈 화면). 구독/충전이 필요하면 web_bridge 로 웹을 연다(앱 내 결제 없음).
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(title: '마이페이지', subtitle: '준비 중입니다.');
  }
}
