import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/design/widgets/app_badge.dart';
import 'package:ssambership_app/features/question_room/data/models/connection_note.dart';
import 'package:ssambership_app/shared/labels/question_room_labels.dart';

/// 연결노트가 author_role(멘토/학생)로 구분되어 렌더되는지.
/// _NoteCard 는 화면 private 이므로, 같은 구성(AppBadge + noteAuthorRole 라벨)으로 검증.
Widget _badgeFor(NoteAuthorRole role) => AppBadge(
      label: QuestionRoomLabels.noteAuthorRole(role),
      tinted: role == NoteAuthorRole.mentor,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('멘토 노트·학생 노트가 각각 한글 작성자 라벨로 구분 렌더',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      Column(
        children: <Widget>[
          _badgeFor(NoteAuthorRole.mentor),
          _badgeFor(NoteAuthorRole.student),
        ],
      ),
    ));
    expect(find.text('멘토'), findsOneWidget);
    expect(find.text('학생'), findsOneWidget);
    // 영문 role 코드 비노출.
    expect(find.text('mentor'), findsNothing);
    expect(find.text('student'), findsNothing);
  });

  test('ConnectionNote.fromMap: author_role 코드 → enum', () {
    final ConnectionNote mentorNote = ConnectionNote.fromMap(<String, dynamic>{
      'id': 'n1',
      'mentor_student_room_id': 'r1',
      'author_role': 'mentor',
      'created_at': '2026-07-01T00:00:00Z',
      'updated_at': '2026-07-01T00:00:00Z',
    });
    expect(mentorNote.authorRole, NoteAuthorRole.mentor);

    final ConnectionNote studentNote = ConnectionNote.fromMap(<String, dynamic>{
      'id': 'n2',
      'mentor_student_room_id': 'r1',
      'author_role': 'student',
      'created_at': '2026-07-01T00:00:00Z',
      'updated_at': '2026-07-01T00:00:00Z',
    });
    expect(studentNote.authorRole, NoteAuthorRole.student);
  });
}
