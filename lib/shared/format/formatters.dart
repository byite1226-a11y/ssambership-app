/// 표시 포맷터. (가격/캐시 포맷은 Commerce-Zero 원칙상 결제에 쓰지 않으며,
/// 잔액 '표시'가 필요할 때만 사용. 미확정 동안은 키만 유지.)
library;

class Formatters {
  Formatters._();

  /// 날짜 한글 표기(간단). 추후 intl 도입 시 교체.
  static String koreanDate(DateTime dt) {
    return '${dt.year}년 ${dt.month}월 ${dt.day}일';
  }
}
