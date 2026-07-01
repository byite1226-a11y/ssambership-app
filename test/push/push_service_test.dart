import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/push/push_service.dart';
import 'package:ssambership_app/core/push/push_types.dart';

import 'push_fakes.dart';

/// 권한 요청 1회 흐름 + 토큰 등록(포트 mock, OS/FCM 미접촉).
void main() {
  test('requestPermissionOnce: 1회만 요청(중복 팝업 방지)', () async {
    final FakePermission perm = FakePermission(PushPermissionStatus.granted);
    final PushService svc = PushService(
      permission: perm,
      tokenProvider: FakeTokenProvider(),
      registrar: FakeRegistrar(),
    );

    expect(svc.hasRequestedOnce, isFalse);
    final PushPermissionStatus s1 = await svc.requestPermissionOnce();
    expect(s1, PushPermissionStatus.granted);
    expect(svc.hasRequestedOnce, isTrue);
    expect(perm.requestCount, 1);

    // 두 번째 호출은 재요청하지 않는다.
    await svc.requestPermissionOnce();
    expect(perm.requestCount, 1);
  });

  test('허용 + userId → 토큰이 계정에 등록된다', () async {
    final FakeRegistrar reg = FakeRegistrar(ready: true);
    final PushService svc = PushService(
      permission: FakePermission(PushPermissionStatus.granted),
      tokenProvider: FakeTokenProvider(token: 'tok-abc'),
      registrar: reg,
    );

    await svc.requestPermissionOnce(userId: 'user-1');
    expect(reg.registerCount, 1);
    expect(reg.registeredUser, 'user-1');
    expect(reg.registeredToken, 'tok-abc');
  });

  test('토큰 공급자 미도입이면 등록을 건너뛴다(골격 안전)', () async {
    final FakeRegistrar reg = FakeRegistrar(ready: true);
    final PushService svc = PushService(
      permission: FakePermission(PushPermissionStatus.granted),
      tokenProvider: FakeTokenProvider(available: false, token: null),
      registrar: reg,
    );
    await svc.registerCurrentToken('user-1');
    expect(reg.registerCount, 0);
  });

  test('거부 상태에서는 등록하지 않는다', () async {
    final FakeRegistrar reg = FakeRegistrar(ready: true);
    final PushService svc = PushService(
      permission: FakePermission(PushPermissionStatus.denied),
      tokenProvider: FakeTokenProvider(),
      registrar: reg,
    );
    final PushPermissionStatus s = await svc.requestPermissionOnce(userId: 'u');
    expect(s, PushPermissionStatus.denied);
    expect(reg.registerCount, 0);
  });

  test('requestPermissionAgain: once 이후에도 재요청(마이페이지 재진입)', () async {
    final FakePermission perm = FakePermission(PushPermissionStatus.denied);
    final PushService svc = PushService(
      permission: perm,
      tokenProvider: FakeTokenProvider(),
      registrar: FakeRegistrar(),
    );
    await svc.requestPermissionOnce();
    expect(perm.requestCount, 1);
    await svc.requestPermissionAgain();
    expect(perm.requestCount, 2); // 다시 물어봄
  });
}
