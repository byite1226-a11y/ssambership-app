import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/auth/auth_service.dart';
import 'core/supabase/supabase_client.dart';
import 'core/deeplink/deep_link_service.dart';
import 'core/push/push_service.dart';

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

  runApp(const SsambershipApp());
}
