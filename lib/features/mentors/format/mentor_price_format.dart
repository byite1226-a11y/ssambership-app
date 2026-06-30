/// 멘토 요금제 표시용 포맷터(가격 '표시'만 — 결제·계산·캐시 트리거 없음).
///
/// ★ Commerce-Zero: 앱은 결제하지 않는다. 여기서는 DB 의 가격을 사람이 읽는
///   문자열로 바꾸기만 한다. 미확정 가격은 호출부에서 '요금제 문의'로 처리한다.
library;

/// 원 단위 정수를 천 단위 콤마 + '원'으로 표시. 예) 29900 → '29,900원'.
String formatWon(int won) {
  final String digits = won.abs().toString();
  final StringBuffer buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final String sign = won < 0 ? '-' : '';
  return '$sign$buf원';
}

/// 요금제 등급(plan_tier) 한글 표기. 코드값은 화면에 노출하지 않는다.
String planTierLabel(String? tier) {
  switch (tier?.trim()) {
    case 'limited':
      return '라이트';
    case 'standard':
      return '스탠다드';
    case 'premium':
      return '프리미엄';
    default:
      return '요금제';
  }
}
