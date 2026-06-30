import '../supabase/supabase_client.dart';

/// 사용자 역할(자리). 화면에는 영문 코드 대신 의미에 맞는 한글 UI를 쓴다.
enum AppRole { student, mentor, admin, guest }

/// 인증 서비스(자리). S0 에서는 골격만 — 실제 로그인/세션 동기화는 후속 세션.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// 현재 로그인 여부(자리). Supabase 세션 연결은 후속.
  bool get isSignedIn {
    final client = SupabaseInit.clientOrNull;
    return client?.auth.currentSession != null;
  }

  /// 현재 역할(자리). 후속에서 users.role 로 매핑. 지금은 guest 폴백.
  AppRole get currentRole => AppRole.guest;
}
