import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/mypage/data/mypage_models.dart';

/// 뷰모델 순수 로직 — 특히 '미확정값 날조 금지' 규칙.
void main() {
  group('SubscriptionCardInfo', () {
    test('statusLabel: active→"구독 중", 아니면 "구독 만료"', () {
      const SubscriptionCardInfo active =
          SubscriptionCardInfo(mentorName: '멘토', isActive: true);
      const SubscriptionCardInfo expired =
          SubscriptionCardInfo(mentorName: '멘토', isActive: false);
      expect(active.statusLabel, '구독 중');
      expect(expired.statusLabel, '구독 만료');
    });

    test('planLabel: 요금제명 미확정(planLabels 비어있음) → null (날조 없음)', () {
      const SubscriptionCardInfo c = SubscriptionCardInfo(
          mentorName: '멘토', isActive: true, planTier: 'standard');
      expect(c.planLabel, isNull);
    });
  });

  group('CashEntry', () {
    test('kindLabel: 증가→충전, 감소→사용 (영문 reason 코드 비노출)', () {
      expect(CashEntry(deltaCents: 100, createdAt: _t).kindLabel, '충전');
      expect(CashEntry(deltaCents: -100, createdAt: _t).kindLabel, '사용');
    });
  });

  group('CashSummary', () {
    test('balanceCents null → hasBalance=false (잔액 미확인 비움)', () {
      expect(const CashSummary().hasBalance, isFalse);
      expect(const CashSummary(balanceCents: 0).hasBalance, isTrue);
    });
  });
}

final DateTime _t = DateTime(2026, 7, 1);
