import '../core/auth/auth_service.dart';

/// 진입 가드: AccessState → 가야 할 경로. router.redirect 에서 사용한다.
///
/// 분기 요약:
/// - loading  → /splash
/// - loggedOut→ /login (보호 경로 직접 접근 시에도 로그인으로)
/// - guest    → /home(제한 탭) + /login 접근 허용
/// - full     → /home
/// - blocked  → /blocked (banned/suspended/상태불명/관리자)
class EntryGuard {
  EntryGuard._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String blocked = '/blocked';
  static const String devGallery = '/dev/gallery';
  static const String devS3 = '/dev/s3';

  /// 게스트가 접근 가능한 하단 탭 인덱스.
  /// (0 질문방 · 1 커뮤니티 · 2 멘토찾기 · 3 알림 · 4 개별질문)
  /// → 커뮤니티(1)·멘토찾기(2)만 허용. 나머지는 로그인 필요.
  /// 마이페이지(우측 상단 프로필 push)도 로그인 필요 — HomeShell 이 가드한다.
  static const Set<int> guestAllowedTabs = <int>{1, 2};

  static bool isTabAllowedForGuest(int index) =>
      guestAllowedTabs.contains(index);

  /// redirect 결정. null = 현재 위치 유지.
  static String? redirect({
    required AccessState access,
    required String location,
  }) {
    // dev 라우트는 가드 제외(개발 빌드 한정으로만 등록됨).
    if (location.startsWith('/dev/')) return null;

    switch (access) {
      case AccessState.loading:
        return location == splash ? null : splash;
      case AccessState.loggedOut:
        return location == login ? null : login;
      case AccessState.guest:
        // 게스트는 홈(제한 탭)과 로그인 화면만.
        if (location == home || location == login) return null;
        return home;
      case AccessState.full:
        return location == home ? null : home;
      case AccessState.blocked:
        return location == blocked ? null : blocked;
    }
  }
}
