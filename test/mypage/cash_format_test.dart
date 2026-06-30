import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mypage/format/cash_format.dart';

/// 캐시 표시 포맷(순수). DB *_cents → 원(cents/100). 값 환산만, 날조 없음.
void main() {
  test('won: cents → "N원" (천단위 콤마)', () {
    expect(CashFormat.won(5000000), '50,000원'); // 5,000,000 cents = 50,000원
    expect(CashFormat.won(0), '0원');
    expect(CashFormat.won(123456), '1,234원'); // 1,234.56 → 절삭
  });

  test('signedWon: 부호 표기', () {
    expect(CashFormat.signedWon(5000000), '+50,000원');
    expect(CashFormat.signedWon(-120000), '-1,200원');
  });
}
