import 'dart:typed_data';

/// 선택된 이미지(메모리) — 스캔 소스(촬영·갤러리·파일) 공통 결과 계약.
///
/// S16에서 question_room/data/attachments 에서 core/scan 으로 이동
/// (attachment_upload.dart 가 re-export 하므로 기존 import 경로도 유효).
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get sizeBytes => bytes.length;
}

/// 파일명 확장자 → MIME 추론(허용목록 기준). XFile.mimeType 이 null 인 플랫폼 대비.
String scanMimeFromName(String name) {
  final String n = name.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.heic')) return 'image/heic';
  if (n.endsWith('.pdf')) return 'application/pdf'; // S19: 파일 소스 PDF.
  return 'image/jpeg'; // jpg/jpeg 및 기타 기본.
}

/// PDF 선택 결과 판별(S19) — 소스 계층이 페이지 래스터화 분기에 쓴다.
/// (화면은 이 판별을 직접 쓰지 않는다 — expandScanPick 뒤에 숨김.)
bool isPdfPickedImage(PickedImage picked) =>
    picked.mimeType.toLowerCase() == 'application/pdf' ||
    picked.fileName.toLowerCase().endsWith('.pdf');
