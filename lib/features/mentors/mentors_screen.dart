import 'package:flutter/material.dart';
import '../../design/widgets/empty_screen.dart';

/// 멘토 찾기(빈 화면). 가격/구매 UI는 노출하지 않는다(Commerce-Zero).
class MentorsScreen extends StatelessWidget {
  const MentorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(title: '멘토 찾기', subtitle: '준비 중입니다.');
  }
}
