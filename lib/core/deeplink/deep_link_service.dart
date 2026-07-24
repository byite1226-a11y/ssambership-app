import 'dart:async';

import '../../app/app_tabs.dart';
import '../push/push_payload.dart';
import '../push/push_service.dart';
import 'notification_deep_link_controller.dart';

/// 딥링크 서비스 — 푸시 '탭' 스트림을 구독해 탭 이동으로 변환한다.
///
/// ★ 판정·중복 제거·로그인 대기는 순수 로직인 [NotificationDeepLinkController] 가
///   담당(테스트 대상). 이 클래스는 배선만: PushService.onOpenedPayload →
///   controller.handleTap → TabNavigator.go.
/// ★ payload 의 link/url 등 외부 경로는 파싱 단계(PushPayload)에서 이미 버려진다 —
///   어떤 URL/외부 scheme 도 실행하지 않는다.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  NotificationDeepLinkController? _controller;
  StreamSubscription<PushPayload>? _sub;

  /// 앱 시작 시 1회 초기화. ★ PushService.initialize() '이전'에 호출해야
  /// 콜드 스타트 최초 메시지를 놓치지 않는다(main.dart 순서 유지).
  Future<void> initialize({PushService? pushService}) async {
    if (_controller != null) return;
    final PushService push = pushService ?? PushService.instance;
    _controller = NotificationDeepLinkController(navigate: TabNavigator.go);
    _sub = push.onOpenedPayload.listen(_onOpened);
  }

  void _onOpened(PushPayload payload) {
    _controller?.handleTap(
      NotificationDeepLinkTarget(
        type: payload.type,
        roomId: payload.roomId,
        threadId: payload.threadId,
        questionId: payload.questionId,
        eventId: payload.eventId,
      ),
    );
  }

  /// 로그인 성공 훅(AuthService) — 유효한 pending 이동을 정확히 1회 실행.
  void onSignedIn(String userId) => _controller?.onSignedIn(userId);

  /// 로그아웃/계정 전환 훅(AuthService) — 이전 사용자의 pending 폐기.
  void onSignedOut() => _controller?.onSignedOut();

  /// 테스트 정리용.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _controller = null;
  }
}
