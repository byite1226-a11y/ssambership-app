import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_payload.dart';
import 'push_ports.dart';

/// 백그라운드 수신 핸들러 — 별도 isolate 에서 호출되므로 반드시 top-level +
/// vm:entry-point 여야 한다. context/플러그인/네비게이션 접근 금지, no-op 안전.
/// (알림 '탭' 처리는 onMessageOpenedApp/getInitialMessage 가 담당 — 여기서 할 일 없음.)
@pragma('vm:entry-point')
Future<void> firebasePushBackgroundHandler(RemoteMessage message) async {
  // 의도적 no-op: 서버 알림함이 정본이라 백그라운드에서 저장/동기화할 것이 없다.
  // ★ 토큰·payload 원문 로그 금지.
}

/// FCM 게이트웨이 — '준비 경계(readiness boundary)' 뒤의 실제 firebase_messaging 구현.
///
/// ★ google-services.json / GoogleService-Info.plist 가 없으면
///   [initialize] 의 Firebase.initializeApp() 이 실패한다 → ready=false 로 두고
///   앱은 조용히 계속(푸시만 비활성). 활성화 절차는 lib/core/push/HANDOFF.md
///   (WAITING_EXTERNAL_FIREBASE_CONFIG) 참조. 모든 호출은 ready 가드 뒤에 있다.
class FirebasePushGateway implements PushGatewayPort {
  FirebasePushGateway();

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebasePushBackgroundHandler);
      _ready = true;
    } catch (_) {
      // 설정 파일 부재 등 — 어떤 실패든 크래시 없이 푸시만 끈다.
      // ★ 원인 객체에 설정값이 섞일 수 있어 값 없이 한 줄만 남긴다.
      debugPrint('푸시 게이트웨이 초기화 생략(Firebase 설정 없음 — HANDOFF 참조)');
      _ready = false;
    }
    return _ready;
  }

  @override
  Future<String?> getToken() async {
    if (!_ready) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null; // APNs 미설정 등 — 토큰 없이 계속(로그 금지).
    }
  }

  @override
  Stream<String> get onTokenRefresh {
    if (!_ready) return const Stream<String>.empty();
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  @override
  Stream<PushPayload> get onForegroundMessage {
    if (!_ready) return const Stream<PushPayload>.empty();
    return FirebaseMessaging.onMessage.map(_toPayload);
  }

  @override
  Stream<PushPayload> get onMessageOpened {
    if (!_ready) return const Stream<PushPayload>.empty();
    return FirebaseMessaging.onMessageOpenedApp.map(_toPayload);
  }

  @override
  Future<PushPayload?> getInitialMessage() async {
    if (!_ready) return null;
    try {
      final RemoteMessage? message =
          await FirebaseMessaging.instance.getInitialMessage();
      return message == null ? null : _toPayload(message);
    } catch (_) {
      return null;
    }
  }

  static PushPayload _toPayload(RemoteMessage message) {
    return PushPayload.fromRemote(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }
}

/// firebase_messaging 기반 권한 포트(Android 13+ POST_NOTIFICATIONS · iOS 공용).
///
/// 매핑: authorized/provisional → granted, denied → denied, 그 외 → notDetermined.
/// ★ '영구 거부' 구분 한계: Android 13+ 는 2회 거부 후 시스템이 팝업을 생략하지만
///   API 는 계속 denied 만 준다(permission_handler 없이는 구분 불가 — 추가하지 않는다).
///   iOS 는 최초 1회만 실제 팝업, 이후 request 는 현재 상태를 되돌려준다.
class FirebasePushPermission implements PushPermissionPort {
  const FirebasePushPermission(this._gateway);

  final PushGatewayPort _gateway;

  @override
  Future<PushPermissionStatus> current() async {
    if (!_gateway.isReady) return PushPermissionStatus.notDetermined;
    try {
      final NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return mapAuthorizationStatus(settings.authorizationStatus);
    } catch (_) {
      return PushPermissionStatus.notDetermined;
    }
  }

  @override
  Future<PushPermissionStatus> request() async {
    if (!_gateway.isReady) return PushPermissionStatus.notDetermined;
    try {
      final NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission();
      return mapAuthorizationStatus(settings.authorizationStatus);
    } catch (_) {
      return PushPermissionStatus.notDetermined;
    }
  }

  /// OS 권한 상태 매핑(순수 — 단위 테스트 진입점).
  @visibleForTesting
  static PushPermissionStatus mapAuthorizationStatus(
      AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PushPermissionStatus.granted;
      case AuthorizationStatus.denied:
        return PushPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return PushPermissionStatus.notDetermined;
    }
  }
}
