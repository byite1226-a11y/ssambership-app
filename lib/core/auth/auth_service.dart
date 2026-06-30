import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../entitlement/entitlement.dart';
import '../supabase/supabase_client.dart';
import 'account_status.dart';

/// 사용자 역할. 화면에는 영문 코드 대신 의미에 맞는 한글 UI를 쓴다.
enum AppRole { student, mentor, admin, guest }

/// 앱 접근 상태 — 진입 분기(entry_guard)의 단일 소스.
/// - loading: 부팅 중(세션 복원/프로필 로드)
/// - loggedOut: 세션 없음 + 게스트 아님 → 로그인 화면
/// - guest: 둘러보기(로그인 없이 제한 입장)
/// - full: 로그인 + 계정 active + role student|mentor → 앱 전체
/// - blocked: 로그인 + (banned|suspended|상태불명) 또는 role admin → 차단 화면
enum AccessState { loading, loggedOut, guest, full, blocked }

/// 인증 서비스 = 세션 + 프로필(role·계정상태·구독) 오케스트레이션.
///
/// ChangeNotifier 로 두어 GoRouter refreshListenable 로 진입 분기를 갱신한다.
/// - 세션: Supabase 이메일+비밀번호 로그인 / 로그아웃 / 앱 재시작 시 복원·유지.
/// - 프로필: 로그인 후 users.role, users.status(account_status), subscriptions(entitlement) read.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  bool _bootstrapping = true;
  bool _guest = false;
  AppRole _role = AppRole.guest;
  AccountState _account = AccountState.unknown;
  Entitlement _entitlement = Entitlement.none;
  StreamSubscription<AuthState>? _authSub;

  // ── 외부 노출 게터 ──
  bool get isBootstrapping => _bootstrapping;
  bool get isGuest => _guest;
  AppRole get currentRole => _role;
  AccountState get accountState => _account;
  Entitlement get entitlement => _entitlement;

  SupabaseClient? get _client => SupabaseInit.clientOrNull;
  Session? get _session => _client?.auth.currentSession;

  /// 현재 로그인 여부(실제 Supabase 세션 기준).
  bool get isSignedIn => _session != null;

  /// 진입 분기용 단일 상태.
  AccessState get access {
    if (_bootstrapping) return AccessState.loading;
    if (isSignedIn) {
      // 계정 차단/상태불명 → 차단.
      if (!_account.isActive) return AccessState.blocked;
      // 관리자 계정은 이 앱(학생·멘토용)에서 차단.
      if (_role == AppRole.admin) return AccessState.blocked;
      if (_role == AppRole.student || _role == AppRole.mentor) {
        return AccessState.full;
      }
      // role 불명(트리거 미생성 등) → 보수적으로 차단.
      return AccessState.blocked;
    }
    if (_guest) return AccessState.guest;
    return AccessState.loggedOut;
  }

  /// 차단 화면에 보여줄 안내 문구.
  String get blockedMessage {
    if (isSignedIn && _role == AppRole.admin && _account.isActive) {
      return '이 앱은 학생·멘토 전용이에요.\n관리자 기능은 웹 콘솔에서 이용해 주세요.';
    }
    return _account.blockedMessage;
  }

  /// 차단 사유가 '상태 불명'(재시도 가능한 경우)인지.
  bool get isRecoverableBlock =>
      isSignedIn &&
      _account.kind == AccountStatusKind.unknown &&
      _role != AppRole.admin;

  /// main() 에서 1회 호출. 세션 복원 + 프로필 로드 + auth 변화 구독.
  Future<void> bootstrap() async {
    final SupabaseClient? client = _client;
    if (client == null) {
      // Supabase 미초기화(키 없음) — 로그인 불가. 게스트/로그아웃 흐름만 동작.
      _bootstrapping = false;
      notifyListeners();
      return;
    }
    _authSub ??= client.auth.onAuthStateChange.listen(_onAuthChange);
    await _loadProfile();
    _bootstrapping = false;
    notifyListeners();
  }

  void _onAuthChange(AuthState data) {
    if (data.event == AuthChangeEvent.signedOut) {
      _resetProfile();
      notifyListeners();
      return;
    }
    // signedIn / tokenRefreshed / initialSession / userUpdated 등 → 프로필 재로드.
    unawaited(_loadProfile().then((_) => notifyListeners()));
  }

  Future<void> _loadProfile() async {
    final SupabaseClient? client = _client;
    final Session? session = _session;
    if (client == null || session == null) {
      _resetProfile();
      return;
    }
    final String userId = session.user.id;
    _role = await _readRole(client, userId);
    _account = await AccountStatusReader.fetch(client, userId);
    if (_role == AppRole.student) {
      _entitlement = await EntitlementReader.fetchForStudent(client, userId);
    } else {
      _entitlement = Entitlement.none;
    }
  }

  void _resetProfile() {
    _role = AppRole.guest;
    _account = AccountState.unknown;
    _entitlement = Entitlement.none;
  }

  Future<AppRole> _readRole(SupabaseClient client, String userId) async {
    try {
      final Map<String, dynamic>? row = await client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      switch ((row?['role'] as String?)?.trim()) {
        case 'student':
          return AppRole.student;
        case 'mentor':
          return AppRole.mentor;
        case 'admin':
          return AppRole.admin;
        default:
          return AppRole.guest;
      }
    } catch (_) {
      return AppRole.guest;
    }
  }

  /// 이메일+비밀번호 로그인. 실패 시 AuthException 전파(화면에서 안내).
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      throw const AuthException('백엔드에 연결되어 있지 않아요. 잠시 후 다시 시도해 주세요.');
    }
    _guest = false;
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    // onAuthStateChange 가 비동기로 갱신하지만, 즉시 반영 위해 한 번 더 로드.
    await _loadProfile();
    notifyListeners();
  }

  /// 둘러보기(게스트 입장).
  void enterAsGuest() {
    _guest = true;
    _resetProfile();
    notifyListeners();
  }

  /// 로그아웃.
  Future<void> signOut() async {
    final SupabaseClient? client = _client;
    _guest = false;
    if (client != null) {
      await client.auth.signOut();
    }
    _resetProfile();
    notifyListeners();
  }

  /// 차단/상태불명 화면에서 프로필 재시도.
  Future<void> reloadProfile() async {
    await _loadProfile();
    notifyListeners();
  }
}
