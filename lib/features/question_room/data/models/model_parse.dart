/// 질문방 모델 공용 파싱 헬퍼. DB(JSON) → Dart 변환 시 null/형식 안전을 모은다.
library;

/// timestamptz(문자열) → 로컬 DateTime. 없거나 깨지면 epoch(0)로 안전 폴백.
DateTime parseTime(Object? raw) {
  if (raw is String) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// nullable timestamptz → DateTime?. 값이 없으면 null 유지(epoch 폴백 안 함).
DateTime? parseTimeOrNull(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal();
  }
  return null;
}
