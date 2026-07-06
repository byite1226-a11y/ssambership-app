import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_error.dart';

/// 예외 → 사용자용 한글 문구(단일 소스).
///
/// ★ 원문 비노출 규약: PostgrestException/StorageException 등 백엔드 예외의
///   원문(테이블·컬럼·RLS 정책명·영문 메시지)은 절대 화면으로 통과시키지 않는다
///   (app_error.dart 의 "내부 코드/DB명 노출 금지" 원칙의 표시 계층 구현).
/// 사용법: SnackBar(content: Text('저장에 실패했어요. ${friendlyError(e)}'))
String friendlyError(Object e) {
  if (e is AppError) return e.userMessage;
  return '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.';
}

/// 로그인(AuthException) 전용 매핑 — login_screen 의 기존 _friendly 를 통합.
/// 원문은 분기 판단에만 쓰고 화면에는 고정 한글 문구만 내보낸다.
String friendlyAuthError(AuthException e) {
  final String m = e.message.toLowerCase();
  if (m.contains('invalid login')) return '이메일 또는 비밀번호가 올바르지 않아요.';
  if (m.contains('email not confirmed')) return '이메일 인증이 완료되지 않았어요.';
  return '로그인에 실패했어요. 이메일과 비밀번호를 확인해 주세요.';
}
