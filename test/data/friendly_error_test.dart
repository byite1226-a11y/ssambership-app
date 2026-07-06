import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ssambership_app/shared/errors/app_error.dart';
import 'package:ssambership_app/shared/errors/friendly_error.dart';

/// friendlyError — 백엔드 예외 원문(테이블·정책명)을 화면으로 통과시키지 않는다.
/// (QA-02 회귀 방지: raw $e 노출 일괄 제거의 단일 소스 검증)
void main() {
  const String generic = '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.';

  test('AppError 는 userMessage 만 노출', () {
    expect(friendlyError(const AppError('로그인이 필요해요.')), '로그인이 필요해요.');
  });

  test('PostgrestException 원문(테이블·제약조건명)을 통과시키지 않는다', () {
    const PostgrestException e = PostgrestException(
      message:
          'duplicate key value violates unique constraint "notifications_pkey"',
      code: '23505',
      details: 'Key (id)=(n1) already exists in table "notifications".',
    );
    final String out = friendlyError(e);
    expect(out, generic);
    expect(out.contains('notifications'), isFalse);
    expect(out.contains('23505'), isFalse);
    expect(out.contains('duplicate'), isFalse);
  });

  test('StorageException·일반 Exception 도 고정 문구로 대체', () {
    expect(
      friendlyError(const StorageException('new row violates row-level '
          'security policy for table "objects"')),
      generic,
    );
    expect(friendlyError(Exception('SocketException: Failed host lookup')),
        generic);
    expect(friendlyError('raw string error'), generic);
  });

  test('friendlyAuthError — 원문은 분기에만 쓰고 한글 고정 문구만 반환', () {
    expect(
      friendlyAuthError(const AuthException('Invalid login credentials')),
      '이메일 또는 비밀번호가 올바르지 않아요.',
    );
    expect(
      friendlyAuthError(const AuthException('Email not confirmed')),
      '이메일 인증이 완료되지 않았어요.',
    );
    final String fallback =
        friendlyAuthError(const AuthException('unexpected_failure at /auth/v1/token'));
    expect(fallback, '로그인에 실패했어요. 이메일과 비밀번호를 확인해 주세요.');
    expect(fallback.contains('/auth/'), isFalse);
  });
}
