import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/mentor_lookup_repository.dart';
import 'package:ssambership_app/features/question_room/data/student_lookup_repository.dart';

/// 공개 표시명 폴백 로직(순수). RPC/네트워크 없이 fromMap + displayName 만 검증.
void main() {
  group('StudentPublic.displayName (멘토가 보는 학생 이름)', () {
    test('nickname 우선', () {
      final StudentPublic s = StudentPublic.fromMap(<String, dynamic>{
        'id': 'u1',
        'nickname': '로컬학생',
        'full_name': '홍길동',
      });
      expect(s.displayName, '로컬학생');
    });

    test('nickname 비면 full_name', () {
      final StudentPublic s = StudentPublic.fromMap(<String, dynamic>{
        'id': 'u1',
        'nickname': '   ',
        'full_name': '홍길동',
      });
      expect(s.displayName, '홍길동');
    });

    test('둘 다 없으면 "학생" 폴백', () {
      final StudentPublic s =
          StudentPublic.fromMap(<String, dynamic>{'id': 'u1'});
      expect(s.displayName, '학생');
    });
  });

  group('MentorPublic.displayName (학생이 보는 멘토 이름)', () {
    test('nickname 우선 → full_name → "멘토" 폴백', () {
      expect(
        MentorPublic.fromMap(
            <String, dynamic>{'id': 'm1', 'nickname': '쌤'}).displayName,
        '쌤',
      );
      expect(
        MentorPublic.fromMap(<String, dynamic>{
          'id': 'm1',
          'full_name': '김선생',
        }).displayName,
        '김선생',
      );
      expect(
        MentorPublic.fromMap(<String, dynamic>{'id': 'm1'}).displayName,
        '멘토',
      );
    });
  });
}
