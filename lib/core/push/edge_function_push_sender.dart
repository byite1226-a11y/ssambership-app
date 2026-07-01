import '../supabase/supabase_client.dart';
import 'push_payload.dart';
import 'push_ports.dart';

/// Edge Function('send-push')을 호출해 특정 사용자에게 푸시를 요청하는 골격.
///
/// ★ Edge Function 은 아직 배포되지 않았다 → [isReady]=false 로 발송을 건너뛴다.
///   서버 배포(인수인계) 후 [_deployed]=true 로 바꾸면 invoke 가 동작한다.
///   ★ 이 클라이언트는 '호출 인터페이스'만 담당한다 — 실제 FCM 전송은 서버(Edge Function).
class EdgeFunctionPushSender implements PushSenderPort {
  const EdgeFunctionPushSender();

  /// 서버 함수명(배포 시 동일하게 맞출 것).
  static const String functionName = 'send-push';

  /// Edge Function 배포 여부(현재 미배포). 배포 후 true 로.
  static const bool _deployed = false;

  @override
  bool get isReady => _deployed && SupabaseInit.isReady;

  @override
  Future<void> send(PushPayload payload, {required String toUserId}) async {
    if (!isReady) return; // 서버 미배포 → 발송 생략(트리거 지점만 준비).
    final client = SupabaseInit.clientOrNull;
    if (client == null) return;
    await client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'to_user_id': toUserId,
        'title': payload.title,
        'body': payload.body,
        'data': payload.toData(), // type + thread_id(딥링크, 화면 비노출)
      },
    );
  }
}
