// 멘토 찾기(공개·열람 전용) 도메인 모델.
//
// 데이터 출처(모두 공개 조회 가능한 소스):
// - 목록: RPC `mentor_directory_list_v2(p_limit)`
// - 프로필: RPC `mentor_profiles_for_directory_v2(p_ids uuid[])`
// - 요금제: 테이블 `mentor_plans` (is_active=true) — 가격은 '표시'만 한다.
//
// ★ 내부 id·딥링크·코드값은 화면에 노출하지 않는다(표시명/한글 라벨만 사용).
import '../format/mentor_price_format.dart';

/// 멘토 공개 요금제 1건(가격 표시 전용 — 결제 트리거 없음).
class MentorPlan {
  const MentorPlan({
    required this.planTier,
    required this.amountCents,
    this.label,
    this.isActive = true,
  });

  final String planTier; // limited / standard / premium (화면 미노출)
  final int amountCents; // 예) 2990000 → 29,900원
  final String? label; // 멘토가 붙인 표기(예: '베이직(주4)'). 없으면 등급명 사용.
  final bool isActive;

  /// 원 단위 가격(amount_cents / 100).
  int get won => amountCents ~/ 100;

  /// 화면 표기명. 멘토가 붙인 라벨이 코드값과 다르면 그것을, 아니면 한글 등급명.
  String get displayLabel {
    final String l = label?.trim() ?? '';
    if (l.isNotEmpty && l != planTier) return l;
    return planTierLabel(planTier);
  }

  factory MentorPlan.fromMap(Map<String, dynamic> map) {
    return MentorPlan(
      planTier: (map['plan_tier'] as String?)?.trim() ?? '',
      amountCents: (map['amount_cents'] as num?)?.toInt() ?? 0,
      label: map['label'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

/// 멘토 공개 프로필(학교/전공/과목/소개/인증 — 공개 필드만).
class MentorProfileInfo {
  const MentorProfileInfo({
    required this.userId,
    this.universityName,
    this.departmentName,
    this.teachingSubjects = const <String>[],
    this.introLine,
    this.verificationStatus,
    this.schoolVerified = false,
  });

  final String userId;
  final String? universityName;
  final String? departmentName;

  /// 지도 과목(이미 한글 라벨로 내려온다 — 예: ['수학','영어']). 그대로 칩 표시.
  final List<String> teachingSubjects;
  final String? introLine;
  final String? verificationStatus; // 'approved' 등
  final bool schoolVerified;

  /// 인증 배지 노출 여부(학교 인증 승인). 민감정보(학생증 등)는 다루지 않는다.
  bool get isVerified =>
      schoolVerified || (verificationStatus?.trim() == 'approved');

  /// '서울대학교 · 수학교육과' 형태. 둘 다 없으면 null.
  String? get schoolLine {
    final String u = universityName?.trim() ?? '';
    final String d = departmentName?.trim() ?? '';
    if (u.isEmpty && d.isEmpty) return null;
    if (u.isEmpty) return d;
    if (d.isEmpty) return u;
    return '$u · $d';
  }

  factory MentorProfileInfo.fromMap(Map<String, dynamic> map) {
    final Object? subjects = map['teaching_subjects'];
    return MentorProfileInfo(
      userId: map['user_id'] as String,
      universityName: map['university_name'] as String?,
      departmentName: map['department_name'] as String?,
      teachingSubjects: subjects is List
          ? subjects
              .map((Object? e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .toList()
          : const <String>[],
      introLine: map['intro_line'] as String?,
      verificationStatus: map['verification_status'] as String?,
      schoolVerified: (map['school_verified'] as bool?) ?? false,
    );
  }
}

/// 멘토 목록 1행(디렉터리 항목 + 프로필 + 활성 요금제).
class MentorListItem {
  const MentorListItem({
    required this.id,
    this.fullName,
    this.nickname,
    this.status,
    this.createdAt,
    this.profile,
    this.plans = const <MentorPlan>[],
  });

  final String id; // 내부용(화면 미노출). 상세 조회·구독 확인에만 사용.
  final String? fullName;
  final String? nickname;
  final String? status;
  final DateTime? createdAt;
  final MentorProfileInfo? profile;
  final List<MentorPlan> plans; // is_active=true 만

  /// 표시명(nickname 우선 → full_name → 폴백 '멘토').
  String get displayName {
    final String n = nickname?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final String f = fullName?.trim() ?? '';
    if (f.isNotEmpty) return f;
    return '멘토';
  }

  List<String> get subjects => profile?.teachingSubjects ?? const <String>[];
  bool get isVerified => profile?.isVerified ?? false;

  /// 최저가 요금제(없으면 null → '요금제 문의').
  MentorPlan? get minPlan {
    if (plans.isEmpty) return null;
    MentorPlan best = plans.first;
    for (final MentorPlan p in plans) {
      if (p.amountCents < best.amountCents) best = p;
    }
    return best;
  }

  /// 카드용 요금 요약. 미확정(요금제 없음)이면 '요금제 문의'(가격 날조 금지).
  String get priceSummary {
    final MentorPlan? m = minPlan;
    if (m == null) return '요금제 문의';
    return '${formatWon(m.won)}부터';
  }

  /// 검색 매칭용 텍스트(이름·학교·전공·과목).
  String get searchHaystack {
    final StringBuffer b = StringBuffer(displayName);
    final MentorProfileInfo? p = profile;
    if (p != null) {
      if (p.universityName != null) b.write(' ${p.universityName}');
      if (p.departmentName != null) b.write(' ${p.departmentName}');
      for (final String s in p.teachingSubjects) {
        b.write(' $s');
      }
    }
    return b.toString();
  }

  MentorListItem copyWith({
    MentorProfileInfo? profile,
    List<MentorPlan>? plans,
  }) {
    return MentorListItem(
      id: id,
      fullName: fullName,
      nickname: nickname,
      status: status,
      createdAt: createdAt,
      profile: profile ?? this.profile,
      plans: plans ?? this.plans,
    );
  }

  factory MentorListItem.fromDirectoryMap(Map<String, dynamic> map) {
    final Object? created = map['created_at'];
    return MentorListItem(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      nickname: map['nickname'] as String?,
      status: map['status'] as String?,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }
}

/// 상세 화면 추가 정보(목록에서 못 가져오는 것: 평균 답변시간·내 구독 여부).
class MentorDetailExtras {
  const MentorDetailExtras({
    this.avgResponseHours,
    this.alreadySubscribed = false,
  });

  /// 평균 답변시간(시간). null = 통계 없음 → '신규 멘토' 친화 표기.
  final num? avgResponseHours;

  /// 현재 로그인 사용자가 이 멘토를 활성 구독 중인지(게스트는 항상 false).
  final bool alreadySubscribed;
}
