import 'package:go_router/go_router.dart';

import '../core/auth/auth_service.dart';
import '../features/auth/blocked_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/dev/dev_flags.dart';
import '../features/dev/widget_gallery.dart';
import 'entry_guard.dart';
import 'home_shell.dart';

/// 라우팅: 스플래시 → (로그인 | 차단 | 홈). 진입 분기는 EntryGuard 가 결정한다.
/// AuthService(ChangeNotifier)를 refreshListenable 로 두어 상태 변화 시 재평가.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: EntryGuard.splash,
    refreshListenable: AuthService.instance,
    redirect: (context, state) => EntryGuard.redirect(
      access: AuthService.instance.access,
      location: state.matchedLocation,
    ),
    routes: <RouteBase>[
      GoRoute(
        path: EntryGuard.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: EntryGuard.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: EntryGuard.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: EntryGuard.blocked,
        builder: (context, state) => const BlockedScreen(),
      ),
      // ★ 개발 전용 — 출시(release) 빌드에서는 등록되지 않는다(kDevToolsEnabled=false).
      if (kDevToolsEnabled)
        GoRoute(
          path: EntryGuard.devGallery,
          builder: (context, state) => const WidgetGallery(),
        ),
    ],
  );
}
