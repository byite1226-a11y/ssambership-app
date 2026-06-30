/// 캐시 잔액·내역 '표시 전용' 포맷. ★ 조회만 — 결제·계산에 쓰지 않는다(Commerce-Zero).
///
/// DB는 `*_cents` 정수(최소 단위)다. 표시는 컬럼 단위 그대로 원(=cents/100)으로 본다.
/// 값을 새로 만들지 않고(날조 없음) DB 정수를 그대로 환산만 한다. 단위 확정 시 한 곳만 고치면 된다.
class CashFormat {
  CashFormat._();

  /// cents 정수 → "12,345원".
  static String won(int cents) => '${_grouped(cents ~/ 100)}원';

  /// 증감(부호 포함) → "+50,000원" / "-1,200원".
  static String signedWon(int deltaCents) {
    final String sign = deltaCents >= 0 ? '+' : '-';
    return '$sign${won(deltaCents.abs())}';
  }

  /// 천 단위 콤마.
  static String _grouped(int v) {
    final String s = v.abs().toString();
    final StringBuffer b = StringBuffer(v < 0 ? '-' : '');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
