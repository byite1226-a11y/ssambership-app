import '../../../core/auth/auth_service.dart';
import '../../../shared/constants/plan_constants.dart';

/// 마이페이지 뷰모델(읽기 전용 조합). 화면은 이 데이터만 보고 그린다(role-aware).
/// ★ 결제·금액 mutate 없음. 미확정 값(요금제명·잔여수)은 비우고 날조하지 않는다.
class MyPageData {
  const MyPageData({
    required this.role,
    required this.profile,
    this.subscriptions = const <SubscriptionCardInfo>[],
    this.cash,
    this.mentor,
  });

  final AppRole role;
  final MyProfile profile;

  /// 학생: 멘토별 구독 카드.
  final List<SubscriptionCardInfo> subscriptions;

  /// 학생: 캐시 잔액·내역(조회). null 이면 섹션 비표시/안내.
  final CashSummary? cash;

  /// 멘토: 답변·정산 요약(조회). null 이면 비표시.
  final MentorDashboard? mentor;

  bool get isMentor => role == AppRole.mentor;
}

/// 프로필 기본 정보.
class MyProfile {
  const MyProfile({
    required this.name,
    required this.roleLabel,
    this.email,
    this.grade,
  });

  final String name;
  final String roleLabel;
  final String? email;

  /// 학년(예: '고2'). DB grade_level 이 이미 한글 표기라 그대로 쓴다. 없으면 비움.
  final String? grade;
}

/// 멘토별 구독 카드(조회). 요금제명은 미확정(planLabels 비어있음)이라 보통 null → 표시 생략.
class SubscriptionCardInfo {
  const SubscriptionCardInfo({
    required this.mentorName,
    required this.isActive,
    this.planTier,
    this.nextRenewal,
    this.remaining,
  });

  final String mentorName;
  final bool isActive;

  /// 내부 코드(limited|standard|premium). 화면엔 [planLabel] 로만.
  final String? planTier;
  final DateTime? nextRenewal;

  /// 잔여 질문수. ★ 미확정이면 null → 숫자 대신 구독 상태로 표기(S4와 동일).
  final int? remaining;

  /// 구독 상태 한글(요금제명 미확정이므로 상태로 표기).
  String get statusLabel => isActive ? '구독 중' : '구독 만료';

  /// 확정된 요금제 한글 라벨만 반환(미확정이면 null → 표시 생략, 날조 없음).
  String? get planLabel {
    final String? code = planTier?.trim();
    if (code == null || code.isEmpty) return null;
    for (final PlanTier t in PlanTier.values) {
      if (t.name == code) {
        final String label = planLabels[t] ?? '';
        return label.isEmpty ? null : label;
      }
    }
    return null;
  }
}

/// 캐시 잔액 요약(조회). balanceCents null → 잔액 미확인(비움).
class CashSummary {
  const CashSummary({this.balanceCents, this.recent = const <CashEntry>[]});

  final int? balanceCents;
  final List<CashEntry> recent;

  bool get hasBalance => balanceCents != null;
}

/// 캐시 내역 한 줄(조회). reason 등 영문 코드는 노출하지 않고 증감 부호로만 유형 표기.
class CashEntry {
  const CashEntry({required this.deltaCents, required this.createdAt});

  final int deltaCents;
  final DateTime createdAt;

  bool get isCredit => deltaCents >= 0;

  /// 유형 한글(코드 비노출): 충전/적립 vs 사용/차감.
  String get kindLabel => isCredit ? '충전' : '사용';
}

/// 멘토 대시보드 요약(조회만). 정산 출금은 웹에서.
class MentorDashboard {
  const MentorDashboard({
    required this.studentCount,
    required this.pendingAnswers,
    this.latestSettlementCents,
  });

  /// 구독(연결) 학생 수.
  final int studentCount;

  /// 답변 대기(pending) 합계 — 멘토가 답할 차례.
  final int pendingAnswers;

  /// 가장 최근 정산 금액(cents, 조회용). 없으면 null → 표시 생략.
  final int? latestSettlementCents;
}
