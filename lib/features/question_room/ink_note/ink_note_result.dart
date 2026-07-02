import 'dart:typed_data';

import '../../../core/ink/ink_document.dart';

/// 필기 화면(InkNoteScreen)이 '완료' 시 호출부로 돌려주는 반환 모델.
///
/// ★ 썸네일은 화면 안에서 생성: renderThumbnailPng 는 캔버스(RepaintBoundary)가
///   붙어 있어야 하므로, 저장 계층이 아니라 필기 화면에서 만들어 여기 담아 넘긴다.
class InkNoteResult {
  const InkNoteResult({
    required this.document,
    required this.modified,
    this.thumbnailPng,
  });

  /// 내보낸 잉크 문서(스트로크 원본 + 캔버스 크기 + 입력 모드).
  final InkDocument document;

  /// 진입 이후 필기 내용이 실제로 바뀌었는지(색·굵기 변경은 제외, 스트로크 기준).
  final bool modified;

  /// 목록용 PNG 썸네일 바이트. 렌더 실패 시 null(저장은 원본만으로도 진행).
  final Uint8List? thumbnailPng;
}
