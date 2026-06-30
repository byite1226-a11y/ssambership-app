import '../core/auth/auth_service.dart';

/// 진입 가드(자리). 라우팅 redirect 에서 사용.
/// S0: 골격만 — 온보딩/로그인 통과 후 홈. 실제 세션 검사·role 분기는 후속.
class EntryGuard {
  EntryGuard._();

  /// 로그인 필요 여부(자리). 지금은 항상 통과시켜 빈 화면 흐름만 확인.
  static bool get requiresLogin => false;

  /// role 기반 시작 경로(자리). 후속에서 student/mentor/admin 분기.
  static String homePathForRole(AppRole role) {
    // TODO: 멘토/관리자 전용 시작 화면 분기.
    return '/home';
  }
}
