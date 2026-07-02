import '../../../core/ink/ink_document.dart';

/// 필기 화면(InkNoteScreen)이 '완료' 시 호출부로 돌려주는 반환 모델.
///
/// ★ 저장 책임 분리: 이 모델은 '무엇을 저장할지'(document)만 담는다.
///   실제 Storage 업로드·connection_notes 갱신은 S14-2 범위이며 여기서 하지 않는다.
class InkNoteResult {
  const InkNoteResult({
    required this.document,
    required this.modified,
  });

  /// 내보낸 잉크 문서(스트로크 원본 + 캔버스 크기 + 입력 모드).
  final InkDocument document;

  /// 진입 이후 필기 내용이 실제로 바뀌었는지(색·굵기 변경은 제외, 스트로크 기준).
  final bool modified;
}
