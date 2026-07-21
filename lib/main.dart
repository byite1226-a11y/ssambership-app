import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/auth/auth_service.dart';
import 'core/supabase/supabase_client.dart';
import 'core/deeplink/deep_link_service.dart';
import 'core/push/push_service.dart';
import 'core/version_gate/version_gate_controller.dart';

/// 진입점.
/// - .env 로드(없어도 앱은 구동) → Supabase 초기화(키 있으면) → 딥링크/푸시 자리 초기화.
/// - 어떤 단계가 실패해도 '빈 앱'은 켜진다(읽기 중심·Commerce-Zero).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드(자산). 없으면 무시하고 진행.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env 미존재 — 연결 없이 빈 앱만 구동.
  }

  // Supabase 초기화(자격값이 있을 때만).
  await SupabaseInit.ensureInitialized();

  // 인증/세션 부팅: 세션 복원 + 프로필(role·계정상태·구독) 로드 + auth 변화 구독.
  await AuthService.instance.bootstrap();

  // 딥링크 → 푸시 순서 유지: 콜드 스타트 알림 탭 메시지를 딥링크 구독자가
  // 먼저 받을 준비를 한 뒤 게이트웨이를 초기화한다. Firebase 설정 파일이 없으면
  // 게이트웨이가 스스로 비활성화되고(준비 경계) 앱은 그대로 켜진다.
  await DeepLinkService.instance.initialize();
  await PushService.instance.initialize(
    // 앱 시작 시 세션이 이미 있으면(자동 로그인) 토큰 등록까지 시도.
    userId: SupabaseInit.clientOrNull?.auth.currentSession?.user.id,
  );

  // 최소 지원 버전 게이트: runApp 전에 검사를 '시작'만 한다(await 하지 않음 —
  // 첫 프레임을 네트워크에 묶지 않는다). 셸(VersionGateShell)이 checking 동안
  // 진입을 보류하고, 결과(pass/forceUpdate/recommend/fetchFailed)에 따라 그린다.
  // anon RPC 라 로그인 전에도 동작한다. android/ios 외 플랫폼은 스스로 건너뛴다.
  unawaited(VersionGateController.instance.start());

  runApp(const SsambershipApp());
}
