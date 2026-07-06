import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/shared/format/formatters.dart';

/// Formatters 경계값 — 미래 시각·자정·연 경계·아주 오래된 날짜.
/// relativeKorean 은 now 주입이 가능해 시계 비의존으로 검증한다.
void main() {
  final DateTime now = DateTime(2026, 7, 6, 12, 0, 0);

  group('relativeKorean 경계', () {
    test('방금(60초 미만)', () {
      expect(
        Formatters.relativeKorean(now.subtract(const Duration(seconds: 59)),
            now: now),
        '방금',
      );
    });

    test('정확히 60초 → 1분 전', () {
      expect(
        Formatters.relativeKorean(now.subtract(const Duration(seconds: 60)),
            now: now),
        '1분 전',
      );
    });

    test('미래 시각(서버-기기 시계 오차)도 예외 없이 표기된다', () {
      // 기기 시계가 서버보다 늦으면 createdAt 이 미래가 될 수 있다.
      // 크래시·음수 표기("-3분 전")만 없으면 합격 — 현재 구현은 '방금'.
      final String label = Formatters.relativeKorean(
          now.add(const Duration(minutes: 3)),
          now: now);
      expect(label, isNotEmpty);
      expect(label.contains('-'), isFalse, reason: '음수 시간 노출 금지');
    });

    test('7일 경계: 6일은 상대, 7일부터 날짜', () {
      expect(
        Formatters.relativeKorean(now.subtract(const Duration(days: 6)),
            now: now),
        '6일 전',
      );
      expect(
        Formatters.relativeKorean(now.subtract(const Duration(days: 7)),
            now: now),
        '2026년 6월 29일',
      );
    });

    test('연 경계를 넘는 과거는 연도 포함 날짜', () {
      expect(
        Formatters.relativeKorean(DateTime(2025, 12, 31), now: now),
        '2025년 12월 31일',
      );
    });
  });

  group('hourMinute / shortDate 경계', () {
    test('자정·한 자리 분은 0 패딩', () {
      expect(Formatters.hourMinute(DateTime(2026, 7, 6, 0, 5)), '00:05');
      expect(Formatters.hourMinute(DateTime(2026, 7, 6, 23, 59)), '23:59');
    });

    test('shortDate 는 패딩 없이 M/D', () {
      expect(Formatters.shortDate(DateTime(2026, 1, 3)), '1/3');
      expect(Formatters.shortDate(DateTime(2026, 12, 25)), '12/25');
    });
  });
}
