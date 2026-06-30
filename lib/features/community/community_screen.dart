import 'package:flutter/material.dart';
import '../../design/widgets/empty_screen.dart';

/// 커뮤니티(빈 화면). 게시판/숏폼은 후속.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(title: '커뮤니티', subtitle: '준비 중입니다.');
  }
}
