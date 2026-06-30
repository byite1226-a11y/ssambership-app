import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Supabase 초기화 + 클라이언트 접근점. 앱은 이 백엔드 1개를 공유한다(읽기 중심).
class SupabaseInit {
  SupabaseInit._();

  static bool _initialized = false;

  /// main() 에서 1회 호출. 자격값이 비어 있으면 초기화를 건너뛴다(빈 앱은 그대로 실행).
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (!AppConfig.hasCredentials) return; // 키 미설정 시 연결 없이 앱만 구동
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.anonKey,
    );
    _initialized = true;
  }

  static bool get isReady => _initialized;

  /// 초기화된 경우에만 클라이언트 반환(아니면 null).
  static SupabaseClient? get clientOrNull =>
      _initialized ? Supabase.instance.client : null;
}
