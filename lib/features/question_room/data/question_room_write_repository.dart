import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import 'models/connection_note.dart';
import 'models/question_message.dart';
import 'models/question_thread.dart';

/// 질문방 쓰기 레포지토리 — RLS를 통과하는 동작만 노출한다.
///
/// ★ 방(mentor_student_rooms) 생성 메서드는 두지 않는다(앱에서 INSERT 정책 없음 = 불가).
/// ★ 잔여(quota) 검증은 이 레이어 책임이 아니다(구독/서버). 여기선 INSERT만 시도하고,
///   RLS/CHECK 위반 시 에러를 삼키지 않고 그대로 올린다.
/// ★ 메시지는 append 전용 — 수정/삭제 메서드 없음.
class QuestionRoomWriteRepository {
  const QuestionRoomWriteRepository();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  /// 현재 로그인 사용자 id(세션). 없으면 에러.
  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppError('로그인이 필요해요.');
    }
    return id;
  }

  /// 스레드 생성. status 는 보내지 않고 DB 기본값('open')에 맡긴다.
  /// quota 검증 없음 — 호출부가 넘긴 값으로 INSERT만 시도(위반 시 예외 전파).
  Future<QuestionThread> createThread({
    required String roomId,
    String? title,
    String? subject,
    String? topic,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('question_threads')
        .insert(<String, dynamic>{
          'mentor_student_room_id': roomId,
          if (title != null) 'title': title,
          if (subject != null) 'subject': subject,
          if (topic != null) 'topic': topic,
        })
        .select()
        .single();
    return QuestionThread.fromMap(row);
  }

  /// 메시지 append. author_id 는 항상 현재 사용자(남의 이름으로 못 씀 — RLS도 차단).
  Future<QuestionMessage> appendMessage({
    required String threadId,
    required String body,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('question_messages')
        .insert(<String, dynamic>{
          'thread_id': threadId,
          'author_id': _uid,
          'body': body,
        })
        .select()
        .single();
    return QuestionMessage.fromMap(row);
  }

  /// 학생이 답변을 확인 처리(status → 'confirmed'). RLS(방 참여자)로 허용된다.
  /// 보통 answered 상태에서 호출하지만 검증은 호출부에서 한다.
  Future<QuestionThread> confirmThread(String threadId) async {
    final Map<String, dynamic> row = await _client
        .from('question_threads')
        .update(<String, dynamic>{'status': 'confirmed'})
        .eq('id', threadId)
        .select()
        .single();
    return QuestionThread.fromMap(row);
  }

  /// 멘토가 답변을 보내며 스레드를 '진행 중'으로 전이(status → 'answered').
  /// ★ 의미: 멘토가 답변 메시지를 남기면 '답변 대기(pending)' → '진행 중(answered)'.
  ///   학생이 확인하면 confirmThread 로 '답변 완료(confirmed)'가 된다(역할 분리).
  ///   RLS상 멘토(방 참여자)가 question_threads.status UPDATE 가능함을 확인했다.
  ///   보통 pending 에서 호출하지만(answered/confirmed 면 호출부가 전이를 생략) 검증은 호출부.
  Future<QuestionThread> markThreadAnswered(String threadId) async {
    final Map<String, dynamic> row = await _client
        .from('question_threads')
        .update(<String, dynamic>{'status': 'answered'})
        .eq('id', threadId)
        .select()
        .single();
    return QuestionThread.fromMap(row);
  }

  /// 내 연결노트 추가/수정. 본인(author_id=현재 사용자) 행만 다룬다.
  /// 같은 방에 내 노트가 있으면 body 갱신, 없으면 새 행 삽입.
  /// author_role 은 현재 사용자 역할에서 채운다(남의 노트는 RLS가 차단).
  Future<ConnectionNote> upsertMyNote({
    required String roomId,
    required String body,
  }) async {
    final String uid = _uid;

    // 내 기존 노트 찾기(본인 것만).
    final Map<String, dynamic>? existing = await _client
        .from('connection_notes')
        .select('id')
        .eq('mentor_student_room_id', roomId)
        .eq('author_id', uid)
        .maybeSingle();

    if (existing != null) {
      final Map<String, dynamic> row = await _client
          .from('connection_notes')
          .update(<String, dynamic>{
            'body': body,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', existing['id'] as String)
          .select()
          .single();
      return ConnectionNote.fromMap(row);
    }

    final Map<String, dynamic> row = await _client
        .from('connection_notes')
        .insert(<String, dynamic>{
          'mentor_student_room_id': roomId,
          'author_id': uid,
          'author_role': _currentAuthorRoleCode(),
          'body': body,
        })
        .select()
        .single();
    return ConnectionNote.fromMap(row);
  }

  /// 현재 사용자 역할 → connection_notes.author_role 코드(student|mentor).
  /// 그 외 역할은 노트 작성 대상이 아니므로 명시적 에러.
  String _currentAuthorRoleCode() {
    switch (AuthService.instance.currentRole) {
      case AppRole.student:
        return 'student';
      case AppRole.mentor:
        return 'mentor';
      case AppRole.admin:
      case AppRole.guest:
        throw const AppError('이 계정은 연결노트를 작성할 수 없어요.');
    }
  }
}
