/// 커뮤니티 모델 공용 파싱 헬퍼. DB(JSON) → Dart 변환 시 null/형식 안전을 모은다.
library;

/// timestamptz(문자열) → 로컬 DateTime. 없거나 깨지면 epoch(0)로 안전 폴백.
DateTime parseTime(Object? raw) {
  if (raw is String) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// 정수 카운트 → int. null/형식오류는 0.
int parseInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? 0;
  return 0;
}
