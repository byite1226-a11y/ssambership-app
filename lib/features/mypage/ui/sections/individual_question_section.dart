import 'package:flutter/material.dart';

import '../../../individual_question/iq_flags.dart';
import '../../../individual_question/ui/mentor_iq_list_screen.dart';
import '../../../individual_question/ui/student_iq_list_screen.dart';
import '../widgets/mypage_section.dart';

/// 개별질문 진입 섹션 — 학생은 내 질문 목록, 멘토는 수락 대기·내 질문 목록으로.
/// 기능 스위치([kIndividualQuestionEnabled])가 꺼져 있으면 아무것도 그리지 않는다.
class IndividualQuestionSection extends StatelessWidget {
  const IndividualQuestionSection({super.key, required this.isMentor});

  final bool isMentor;

  @override
  Widget build(BuildContext context) {
    if (!kIndividualQuestionEnabled) return const SizedBox.shrink();
    return MyPageSection(
      title: '개별질문',
      child: MyPageRow(
        icon: Icons.help_outline,
        label: isMentor ? '받은 개별질문' : '내 개별질문',
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => isMentor
                ? const MentorIqListScreen()
                : const StudentIqListScreen(),
          ),
        ),
      ),
    );
  }
}
