/// 앱 공통 에러 표현. 화면에는 내부 코드/스택을 노출하지 않고 사용자용 메시지만 보여준다.
library;

class AppError implements Exception {
  const AppError(this.userMessage, {this.cause});

  /// 사용자에게 보여줄 한글 메시지(영문 코드/DB명/UUID 노출 금지).
  final String userMessage;

  /// 내부 원인(로깅용 — 화면 표시 금지).
  final Object? cause;

  @override
  String toString() => 'AppError($userMessage)';
}
