import 'package:firebase_messaging/firebase_messaging.dart'
    show AuthorizationStatus;
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/auth/auth_service.dart';
import 'package:ssambership_app/core/push/firebase_push_gateway.dart';
import 'package:ssambership_app/core/push/push_payload.dart';
import 'package:ssambership_app/core/push/push_ports.dart';
import 'package:ssambership_app/core/push/push_service.dart';

import 'push_fakes.dart';

/// 토큰 수명주기·권한·준비 경계(포트 fake 주입, 실제 Firebase/서버 미접촉).
void main() {
  PushService build({
    required FakePushGateway gateway,
    required FakePermission permission,
    required FakeRegistrar registrar,
    String platform = 'android',
  }) {
    return PushService(
      gateway: gateway,
      permission: permission,
      registrar: registrar,
      platform: platform,
    );
  }

  group('토큰 수명주기', () {
    test('로그인 → 권한 허용·준비 시 토큰을 RPC 인자(token/platform)로 등록한다', () async {
      final FakeRegistrar reg = FakeRegistrar();
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-abc'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
        platform: 'ios',
      );

      await svc.onSignedIn('user-1');

      expect(reg.registeredTokens, <String>['tok-abc']);
      expect(reg.registeredPlatforms, <String>['ios']);
      expect(svc.hasRegisteredToken, isTrue);
      expect(svc.deviceTokenIdForTest, 'dtid-1');
    });

    test('앱 시작(세션 존재) → initialize(userId)만으로 등록된다', () async {
      final FakeRegistrar reg = FakeRegistrar();
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-boot'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );

      await svc.initialize(userId: 'user-1');

      expect(reg.registeredTokens, <String>['tok-boot']);
    });

    test('토큰 회전(onTokenRefresh) → 재등록하고 기억 id 를 갱신한다', () async {
      final FakeRegistrar reg = FakeRegistrar();
      final FakePushGateway gw = FakePushGateway(token: 'tok-1');
      final PushService svc = build(
        gateway: gw,
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );

      await svc.initialize(userId: 'user-1');
      expect(reg.registerCount, 1);

      gw.token = 'tok-2';
      reg.nextDeviceTokenId = 'dtid-2';
      gw.tokenRefresh.add('tok-2');
      await pumpEventQueue();

      expect(reg.registeredTokens, <String>['tok-1', 'tok-2']);
      expect(svc.deviceTokenIdForTest, 'dtid-2');
    });

    test('로그아웃: 철회(revoke)가 supabase signOut 보다 반드시 먼저다(순서 기록)', () async {
      final List<String> journal = <String>[];
      final FakeRegistrar reg = FakeRegistrar(journal: journal);
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-1'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );
      await svc.onSignedIn('user-1');

      await AuthService.performSignOut(
        revokePushToken: svc.revokeBeforeSignOut,
        supabaseSignOut: () async => journal.add('supabase-signout'),
      );

      expect(journal, <String>['register', 'revoke', 'supabase-signout']);
      expect(reg.revokedTokens, <String>['tok-1']);
      expect(svc.hasRegisteredToken, isFalse); // 기억 상태 정리.
    });

    test('철회 실패해도 로그아웃은 진행되고 기억 상태는 정리된다(비차단)', () async {
      final List<String> journal = <String>[];
      final FailingRevokeRegistrar reg =
          FailingRevokeRegistrar(journal: journal);
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-1'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );
      await svc.onSignedIn('user-1');

      await AuthService.performSignOut(
        revokePushToken: svc.revokeBeforeSignOut,
        supabaseSignOut: () async => journal.add('supabase-signout'),
      );

      expect(
          journal, <String>['register', 'revoke-failed', 'supabase-signout']);
      expect(svc.hasRegisteredToken, isFalse);
    });

    test('계정 전환: 로그아웃 후 새 로그인 → 재등록만으로 끝난다(서버 재소유)', () async {
      final FakeRegistrar reg = FakeRegistrar();
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-1'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );

      await svc.onSignedIn('user-a');
      await svc.revokeBeforeSignOut();
      await svc.onSignedIn('user-b');

      expect(reg.registerCount, 2); // 같은 토큰 재등록 — 서버가 원자적 재소유.
      expect(reg.revokedTokens, <String>['tok-1']);
    });

    test('등록 실패 → 상태 미기억(재시도 가능), 다음 시도에서 성공한다', () async {
      final FakeRegistrar reg = FakeRegistrar()..failNextRegisters = 1;
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-1'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );

      await svc.onSignedIn('user-1'); // 1차: 실패(예외는 내부에서 삼킴).
      expect(svc.hasRegisteredToken, isFalse);
      expect(svc.deviceTokenIdForTest, isNull);

      await svc.onSignedIn('user-1'); // 2차: 성공.
      expect(reg.registerCount, 1);
      expect(svc.hasRegisteredToken, isTrue);
    });

    test('등록 실패 상태에서도 로그아웃은 완료된다(철회할 토큰 없음 → revoke 생략)', () async {
      final List<String> journal = <String>[];
      final FakeRegistrar reg = FakeRegistrar(journal: journal)
        ..failNextRegisters = 1;
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-1'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );
      await svc.onSignedIn('user-1');

      await AuthService.performSignOut(
        revokePushToken: svc.revokeBeforeSignOut,
        supabaseSignOut: () async => journal.add('supabase-signout'),
      );

      expect(journal, <String>['supabase-signout']); // 등록된 토큰 없음 — 철회 생략.
    });
  });

  group('권한', () {
    test(
        'OS 권한 매핑: authorized/provisional→granted, denied→denied, 미결정→notDetermined',
        () {
      expect(
        FirebasePushPermission.mapAuthorizationStatus(
            AuthorizationStatus.authorized),
        PushPermissionStatus.granted,
      );
      expect(
        FirebasePushPermission.mapAuthorizationStatus(
            AuthorizationStatus.provisional),
        PushPermissionStatus.granted,
      );
      expect(
        FirebasePushPermission.mapAuthorizationStatus(
            AuthorizationStatus.denied),
        PushPermissionStatus.denied,
      );
      expect(
        FirebasePushPermission.mapAuthorizationStatus(
            AuthorizationStatus.notDetermined),
        PushPermissionStatus.notDetermined,
      );
    });

    test('거부 상태 → getToken/등록을 시도하지 않는다', () async {
      final FakeRegistrar reg = FakeRegistrar();
      final FakePushGateway gw = FakePushGateway(token: 'tok-1');
      final PushService svc = build(
        gateway: gw,
        permission: FakePermission(PushPermissionStatus.denied),
        registrar: reg,
      );

      await svc.onSignedIn('user-1');
      final PushPermissionStatus s =
          await svc.requestPermissionOnce(userId: 'user-1');

      expect(s, PushPermissionStatus.denied);
      expect(gw.getTokenCount, 0);
      expect(reg.registerCount, 0);
    });

    test('requestPermissionOnce: 1회만 요청(중복 팝업 방지), Again 은 재요청', () async {
      final FakePermission perm = FakePermission(PushPermissionStatus.denied);
      final PushService svc = build(
        gateway: FakePushGateway(),
        permission: perm,
        registrar: FakeRegistrar(),
      );

      await svc.requestPermissionOnce();
      await svc.requestPermissionOnce();
      expect(perm.requestCount, 1);

      await svc.requestPermissionAgain();
      expect(perm.requestCount, 2);
    });

    test('요청 후 허용 + userId → 즉시 등록까지 이어진다', () async {
      final FakeRegistrar reg = FakeRegistrar();
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-1'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );

      await svc.requestPermissionOnce(userId: 'user-1');
      expect(reg.registeredTokens, <String>['tok-1']);
    });
  });

  group('준비 경계(게이트웨이 초기화 실패)', () {
    test('크래시 없이 계속되고, 등록 시도·권한 요청이 전부 no-op 이다', () async {
      final FakePermission perm = FakePermission(PushPermissionStatus.granted);
      final FakeRegistrar reg = FakeRegistrar();
      final FakePushGateway gw = FakePushGateway(ready: false);
      final PushService svc = build(
        gateway: gw,
        permission: perm,
        registrar: reg,
      );

      await svc.initialize(userId: 'user-1'); // 크래시 없음.
      await svc.onSignedIn('user-1');
      final PushPermissionStatus s =
          await svc.requestPermissionOnce(userId: 'user-1');

      expect(gw.getTokenCount, 0);
      expect(reg.registerCount, 0);
      expect(perm.requestCount, 0); // 권한 팝업도 미준비면 띄우지 않는다.
      expect(s, PushPermissionStatus.notDetermined);
    });

    test('레지스트라 미준비(백엔드 없음) → 등록 생략', () async {
      final FakeRegistrar reg = FakeRegistrar(ready: false);
      final PushService svc = build(
        gateway: FakePushGateway(token: 'tok-1'),
        permission: FakePermission(PushPermissionStatus.granted),
        registrar: reg,
      );
      await svc.onSignedIn('user-1');
      expect(reg.registerCount, 0);
    });
  });

  group('수신 스트림', () {
    test('포그라운드/탭/콜드스타트 메시지가 payload 스트림으로 흐른다', () async {
      final FakePushGateway gw = FakePushGateway();
      gw.initialMessage = _payload(type: 'question_answered', eventId: 'n-0');
      final PushService svc = build(
        gateway: gw,
        permission: FakePermission(PushPermissionStatus.notDetermined),
        registrar: FakeRegistrar(),
      );

      final List<String> foreground = <String>[];
      final List<String> opened = <String>[];
      svc.onForegroundPayload.listen((p) => foreground.add(p.eventId));
      svc.onOpenedPayload.listen((p) => opened.add(p.eventId));

      await svc.initialize(); // 콜드 스타트 최초 메시지 → opened 로 흘러야 한다.
      gw.foreground.add(_payload(type: 'question_answered', eventId: 'n-1'));
      gw.opened.add(_payload(type: 'question_answered', eventId: 'n-2'));
      await pumpEventQueue();

      expect(foreground, <String>['n-1']);
      expect(opened, <String>['n-0', 'n-2']);
    });
  });
}

PushPayload _payload({required String type, required String eventId}) =>
    PushPayload.fromRemote(<String, dynamic>{
      'type': type,
      'room_id': 'r-1',
      'notification_id': eventId,
    });
