import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'models/question_message.dart';

/// 스레드 실시간 포트 — 새 메시지(insert)와 스레드 상태 변경(update)을 콜백으로 전달.
///
/// 화면(채팅/답변)은 이 포트를 주입받아 구독한다. 테스트에서는 fake 를 주입해
/// 실제 네트워크 없이 메시지 방출을 흉내낸다.
abstract class ThreadRealtimePort {
  /// 구독 시작. [onMessageInsert] 는 새 메시지마다, [onThreadUpdate] 는 스레드 변경 시 호출.
  void start({
    required void Function(QuestionMessage message) onMessageInsert,
    void Function()? onThreadUpdate,
  });

  /// 구독 정리(누수 금지). 화면 dispose 에서 호출.
  Future<void> dispose();
}

/// Supabase Realtime 구현(postgres_changes).
///
/// ★ 인프라 의존(인수인계): question_messages / question_threads 가 `supabase_realtime`
///   publication 에 포함돼 있어야 이벤트가 도착한다. 미포함이면 콜백이 오지 않으며,
///   화면은 '전송 후 재조회 / 수동 새로고침' 폴백으로 계속 동작한다(누락 없음).
///   publication 변경은 이 작업 범위 밖(마이그레이션 금지) — 오너/동업자 확인 필요.
class SupabaseThreadRealtime implements ThreadRealtimePort {
  SupabaseThreadRealtime(this.threadId);

  final String threadId;
  RealtimeChannel? _channel;

  @override
  void start({
    required void Function(QuestionMessage message) onMessageInsert,
    void Function()? onThreadUpdate,
  }) {
    final SupabaseClient? client = SupabaseInit.clientOrNull;
    if (client == null) return; // 백엔드 미연결 → 조용히 무시(폴백만 동작).

    final RealtimeChannel channel = client.channel('question_thread_$threadId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'question_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'thread_id',
        value: threadId,
      ),
      callback: (PostgresChangePayload payload) {
        try {
          onMessageInsert(QuestionMessage.fromMap(payload.newRecord));
        } catch (_) {
          // 파싱 실패는 무시(폴백 재조회가 보완).
        }
      },
    );

    if (onThreadUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'question_threads',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: threadId,
        ),
        callback: (_) => onThreadUpdate(),
      );
    }

    channel.subscribe();
    _channel = channel;
  }

  @override
  Future<void> dispose() async {
    final RealtimeChannel? ch = _channel;
    _channel = null;
    if (ch != null) {
      await SupabaseInit.clientOrNull?.removeChannel(ch);
    }
  }
}
