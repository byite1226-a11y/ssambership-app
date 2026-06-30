import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import 'models/connection_note.dart';
import 'models/question_attachment.dart';
import 'models/question_message.dart';
import 'models/question_thread.dart';
import 'models/room.dart';

/// 질문방 읽기 전용 레포지토리.
///
/// ★ 권한 필터는 추가 코드로 만들지 않는다 — DB RLS('그 방의 student/mentor 본인만')에 의존.
///   즉 myRooms()는 별도 where 없이도 RLS가 내 방만 돌려준다.
///   에러는 삼키지 않고 그대로 전파한다(호출부/화면에서 처리).
class QuestionRoomReadRepository {
  const QuestionRoomReadRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  /// 내가 참여한 방 목록(최근 활동순). RLS가 student_id/mentor_id 본인 방만 통과시킨다.
  Future<List<Room>> myRooms() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('mentor_student_rooms')
        .select('*')
        .order('updated_at', ascending: false);
    return rows.map(Room.fromMap).toList();
  }

  /// 방의 질문 스레드 목록(최신순).
  Future<List<QuestionThread>> threads(String roomId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('question_threads')
        .select('*')
        .eq('mentor_student_room_id', roomId)
        .order('created_at', ascending: false);
    return rows.map(QuestionThread.fromMap).toList();
  }

  /// 스레드의 메시지 목록(대화 순서 = created_at 오름차순).
  Future<List<QuestionMessage>> messages(String threadId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('question_messages')
        .select('*')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return rows.map(QuestionMessage.fromMap).toList();
  }

  /// 방의 연결노트 전부(학생·멘토 섞여 옴, 최근 수정순).
  /// 작성자 구분은 각 행의 authorRole 로 — 호출부에서 역할별로 나눠 쓸 수 있다.
  Future<List<ConnectionNote>> notes(String roomId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('connection_notes')
        .select('*')
        .eq('mentor_student_room_id', roomId)
        .order('updated_at', ascending: false);
    return rows.map(ConnectionNote.fromMap).toList();
  }

  /// 스레드의 첨부 목록(골격). 화면 연결은 S6.
  Future<List<QuestionAttachment>> attachments(String threadId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('question_attachments')
        .select('*')
        .eq('thread_id', threadId)
        .order('created_at', ascending: false);
    return rows.map(QuestionAttachment.fromMap).toList();
  }
}
