/// 잉크 Storage 경로 규약 — '원본 JSON 과 목록용 PNG 썸네일을 분리 저장'
/// (연결노트 필기 기획서 5-2) 원칙의 단일 소스.
///
/// ★ 기존 구조 재사용: 새 도메인 없이 Supabase Storage 버킷 하나를 쓴다.
///   버킷 생성·정책("방 참여자만 read/write")은 오너 인프라 작업 —
///   attachment_upload.dart 의 graceful 패턴을 S14 저장 계층에서 동일 적용.
///
/// 경로 형식:
///   ink-notes/{roomId}/{noteId}/ink.json        ← 필기 원본(봉투+스케치)
///   ink-notes/{roomId}/{noteId}/thumb.png       ← 목록용 썸네일
///   ink-annotations/{roomId}/{attachmentId}/ink.json   ← 스캔 주석(S15)
///   ink-annotations/{roomId}/{attachmentId}/flat.png   ← 평탄화 출력(S15)
class InkStoragePaths {
  InkStoragePaths._();

  /// 버킷 이름(오너가 실제 생성 시 웹과 통일 — 다르면 이 상수만 수정).
  static const String bucket = 'ink-notes';

  static const String _docFile = 'ink.json';
  static const String _thumbFile = 'thumb.png';
  static const String _flatFile = 'flat.png';

  /// 연결노트 필기 원본 경로.
  static String noteDocument(String roomId, String noteId) =>
      'ink-notes/${_seg(roomId)}/${_seg(noteId)}/$_docFile';

  /// 연결노트 필기 썸네일 경로.
  static String noteThumbnail(String roomId, String noteId) =>
      'ink-notes/${_seg(roomId)}/${_seg(noteId)}/$_thumbFile';

  /// 스캔 주석 원본 경로(S15).
  static String annotationDocument(String roomId, String attachmentId) =>
      'ink-annotations/${_seg(roomId)}/${_seg(attachmentId)}/$_docFile';

  /// 스캔 주석 평탄화 이미지 경로(S15, 첨부·미리보기용).
  static String annotationFlattened(String roomId, String attachmentId) =>
      'ink-annotations/${_seg(roomId)}/${_seg(attachmentId)}/$_flatFile';

  /// 경로 세그먼트 검증 — 빈 값·구분자 포함 ID 는 호출부 버그.
  static String _seg(String id) {
    if (id.isEmpty || id.contains('/') || id.contains('..')) {
      throw ArgumentError('Storage 경로 세그먼트 불량: "$id"');
    }
    return id;
  }
}
