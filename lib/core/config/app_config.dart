import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 설정. Supabase URL/anon key 는 코드에 하드코딩하지 않고 .env 에서 읽는다.
///
/// 개발=로컬 Supabase. URL 은 플랫폼별로 분기한다:
///   - Android 에뮬레이터 : http://10.0.2.2:54321 (호스트 127.0.0.1 매핑)
///   - iOS 시뮬레이터/데스크탑 : .env SUPABASE_URL (http://127.0.0.1:54321)
///   - 실기기 : .env SUPABASE_URL_LAN (PC LAN IP) — 비어있으면 기본 URL 폴백
///
/// 출시 시: .env 를 원격 production URL/anon key 로 교체하면 분기 로직과 무관하게 동작.
class AppConfig {
  AppConfig._();

  static String get _baseUrl =>
      dotenv.maybeGet('SUPABASE_URL') ?? 'http://127.0.0.1:54321';

  static String get _lanUrl => dotenv.maybeGet('SUPABASE_URL_LAN') ?? '';

  static String get anonKey => dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  /// 원격(*.supabase.co)이면 플랫폼 분기 없이 그대로 사용.
  static bool get _isRemote => _baseUrl.contains('supabase.co');

  /// 플랫폼별 Supabase URL.
  static String get supabaseUrl {
    if (_isRemote) return _baseUrl;
    if (kIsWeb) return _baseUrl;
    // Android 에뮬레이터는 호스트 루프백을 10.0.2.2 로 본다.
    if (Platform.isAndroid) {
      // 실기기에서 LAN IP 가 지정돼 있으면 그것을 우선.
      if (_lanUrl.isNotEmpty) return _lanUrl;
      return _baseUrl.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    // iOS 시뮬레이터/데스크탑은 127.0.0.1 그대로(실기기는 LAN URL).
    if (_lanUrl.isNotEmpty && (Platform.isIOS)) return _lanUrl;
    return _baseUrl;
  }

  /// 설정이 채워졌는지(연결 시도 가능 여부).
  static bool get hasCredentials =>
      supabaseUrl.isNotEmpty && anonKey.isNotEmpty;
}
