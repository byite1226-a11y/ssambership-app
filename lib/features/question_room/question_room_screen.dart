import 'package:flutter/material.dart';
import '../../design/widgets/empty_screen.dart';

/// 질문방(빈 화면). 학생/멘토 분기는 후속.
class QuestionRoomScreen extends StatelessWidget {
  const QuestionRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(title: '질문방');
  }
}
