/// 잉크 Storage 경로 규약 — '원본 JSON 과 목록용 PNG 썸네일을 분리 저장'
/// (연결노트 필기 기획서 5-2) 원칙의 단일 소스.
///
/// ★ 버킷 상대 경로: 반환 경로는 버킷 이름을 포함하지 않는다(Storage API 가
///   `from(bucket).xxx(path)` 로 버킷을 따로 받기 때문).
/// ★ 정책 정합: 연결노트 필기 버킷 정책은 '경로 첫 세그먼트 = room UUID 이고,
///   요청자가 그 방의 student_id/mentor_id 일 때만 read/write' 다. 따라서 첫
///   세그먼트는 반드시 roomId, 둘째 세그먼트는 작성자(authorId)로 둔다.
///
/// 경로 형식(버킷 상대):
///   connection-note-ink:  {roomId}/{authorId}/ink.json     ← 필기 원본(봉투+스케치)
///                         {roomId}/{authorId}/thumb.png    ← 목록용 썸네일
///   scan-annotations:     {roomId}/{attachmentId}/ink.json ← 스캔 주석 원본(S15)
///                         {roomId}/{attachmentId}/flat.png ← 평탄화 출력(S15)
class InkStoragePaths {
  InkStoragePaths._();

  /// 연결노트 필기 버킷(비공개). 정책: 첫 세그먼트=roomId, 방 참여자만 read/write.
  static const String bucket = 'connection-note-ink';

  /// 스캔 주석 버킷(S15 대비 상수만 정의).
  static const String annotationBucket = 'scan-annotations';

  static const String _docFile = 'ink.json';
  static const String _thumbFile = 'thumb.png';
  static const String _flatFile = 'flat.png';

  /// 연결노트 필기 원본 경로(작성자별 1개). 첫 세그먼트=roomId(정책 통과 조건).
  static String noteDocument(String roomId, String authorId) =>
      '${_seg(roomId)}/${_seg(authorId)}/$_docFile';

  /// 연결노트 필기 썸네일 경로.
  static String noteThumbnail(String roomId, String authorId) =>
      '${_seg(roomId)}/${_seg(authorId)}/$_thumbFile';

  /// 스캔 주석 원본 경로(S15).
  static String annotationDocument(String roomId, String attachmentId) =>
      '${_seg(roomId)}/${_seg(attachmentId)}/$_docFile';

  /// 스캔 주석 평탄화 이미지 경로(S15, 첨부·미리보기용).
  static String annotationFlattened(String roomId, String attachmentId) =>
      '${_seg(roomId)}/${_seg(attachmentId)}/$_flatFile';

  /// 경로 세그먼트 검증 — 빈 값·구분자 포함 ID 는 호출부 버그.
  static String _seg(String id) {
    if (id.isEmpty || id.contains('/') || id.contains('..')) {
      throw ArgumentError('Storage 경로 세그먼트 불량: "$id"');
    }
    return id;
  }
}
