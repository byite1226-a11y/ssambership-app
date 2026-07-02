import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/auth/auth_service.dart';
import 'package:ssambership_app/features/individual_question/data/models/individual_question_models.dart';
import 'package:ssambership_app/features/individual_question/ui/iq_detail_screen.dart';
import 'package:ssambership_app/features/individual_question/ui/mentor_iq_list_screen.dart';
import 'package:ssambership_app/features/individual_question/ui/student_iq_list_screen.dart';

IndividualQuestion _question({
  String id = 'q1',
  IndividualQuestionType type = IndividualQuestionType.open,
  IndividualQuestionStatus status = IndividualQuestionStatus.open,
  String title = '수열 질문이에요',
  int priceCents = 500000,
}) {
  return IndividualQuestion(
    id: id,
    studentId: 's1',
    type: type,
    status: status,
    title: title,
    body: '문제 본문',
    priceCents: priceCents,
    createdAt: DateTime(2026, 7, 1),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('StudentIqListScreen', () {
    testWidgets('빈 목록 → 빈 상태 안내', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(StudentIqListScreen(
        loaderOverride: () async => <IndividualQuestion>[],
      )));
      await tester.pumpAndSettle();
      expect(find.text('아직 개별질문이 없어요'), findsOneWidget);
    });

    testWidgets('목록: 제목·상태 라벨·가격 표시', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(StudentIqListScreen(
        loaderOverride: () async => <IndividualQuestion>[
          _question(status: IndividualQuestionStatus.answered),
        ],
      )));
      await tester.pumpAndSettle();
      expect(find.text('수열 질문이에요'), findsOneWidget);
      expect(find.text('답변완료'), findsOneWidget);
      expect(find.text('5,000캐시'), findsOneWidget);
    });
  });

  group('MentorIqListScreen', () {
    testWidgets('수락 대기(공개형) + 내 질문 섹션', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(MentorIqListScreen(
        loaderOverride: () async => MentorIqListData(
          open: <OpenIndividualQuestion>[
            OpenIndividualQuestion(
              id: 'o1',
              title: '확률 질문',
              priceCents: 300000,
              createdAt: DateTime(2026, 7, 1),
            ),
          ],
          mine: <IndividualQuestion>[
            _question(
              id: 'q2',
              type: IndividualQuestionType.direct,
              status: IndividualQuestionStatus.assigned,
              title: '기하 질문',
            ),
          ],
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('수락 대기 (공개형)'), findsOneWidget);
      expect(find.text('확률 질문'), findsOneWidget);
      expect(find.text('수락하고 답변하기'), findsOneWidget);
      expect(find.text('내 질문'), findsOneWidget);
      expect(find.text('기하 질문'), findsOneWidget);
    });

    testWidgets('둘 다 비면 빈 상태', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(MentorIqListScreen(
        loaderOverride: () async => const MentorIqListData(
          open: <OpenIndividualQuestion>[],
          mine: <IndividualQuestion>[],
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('아직 개별질문이 없어요'), findsOneWidget);
    });
  });

  group('IqDetailScreen', () {
    IqDetailData detail(IndividualQuestionStatus status,
        {List<IqMessage> messages = const <IqMessage>[]}) {
      return IqDetailData(
        question: _question(status: status),
        messages: messages,
        attachments: const <IqAttachment>[],
        mentorName: '수학멘토',
      );
    }

    testWidgets('학생·답변완료 → 해결 완료 버튼, 취소 버튼 없음',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(IqDetailScreen(
        questionId: 'q1',
        roleOverride: AppRole.student,
        loaderOverride: () async => detail(
          IndividualQuestionStatus.answered,
          messages: <IqMessage>[
            IqMessage(
              id: 'm1',
              questionId: 'q1',
              authorId: 'mentor',
              body: '이렇게 풀어요',
              createdAt: DateTime(2026, 7, 2),
            ),
          ],
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('해결 완료 (멘토에게 정산)'), findsOneWidget);
      expect(find.text('질문 취소 (캐시 환불)'), findsNothing);
      expect(find.text('이렇게 풀어요'), findsOneWidget);
    });

    testWidgets('학생·답변 대기 → 취소 버튼, 해결 완료 없음',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(IqDetailScreen(
        questionId: 'q1',
        roleOverride: AppRole.student,
        loaderOverride: () async => detail(IndividualQuestionStatus.open),
      )));
      await tester.pumpAndSettle();
      expect(find.text('질문 취소 (캐시 환불)'), findsOneWidget);
      expect(find.text('해결 완료 (멘토에게 정산)'), findsNothing);
    });

    testWidgets('멘토·답변중 → 답변 작성 폼', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(IqDetailScreen(
        questionId: 'q1',
        roleOverride: AppRole.mentor,
        loaderOverride: () async => detail(IndividualQuestionStatus.claimed),
      )));
      await tester.pumpAndSettle();
      expect(find.text('답변 작성'), findsOneWidget);
      expect(find.text('답변 등록'), findsOneWidget);
    });

    testWidgets('멘토·정산 완료 → 안내만', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(IqDetailScreen(
        questionId: 'q1',
        roleOverride: AppRole.mentor,
        loaderOverride: () async => detail(IndividualQuestionStatus.released),
      )));
      await tester.pumpAndSettle();
      expect(find.text('정산이 완료된 질문이에요.'), findsOneWidget);
      expect(find.text('답변 등록'), findsNothing);
    });
  });
}
