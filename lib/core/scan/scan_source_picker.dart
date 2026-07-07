import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/errors/app_error.dart';
import 'picked_image.dart';

/// 스캔 소스 3종(S16, docs/SCAN_INK_PLAN.md §6-1).
enum ScanSource { camera, gallery, file }

/// 스캔 장변 캡(§6-4 규약): 촬영·갤러리는 선택 시점에 이 값으로 리사이즈된다.
const double kScanMaxLongSidePx = 4096;

/// 파일 소스 허용 '이미지' 확장자.
const List<String> kScanFileExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
];

/// 파일 소스 선택 대화상자에 노출할 전체 확장자(이미지 + PDF, S19).
const List<String> kScanFilePickerExtensions = <String>[
  ...kScanFileExtensions,
  'pdf',
];

/// 스캔 소스 통합 포트 — 어떤 소스든 결과는 기존 [PickedImage] 계약.
///
/// 테스트는 fake 를 주입해 플러그인 비접촉으로 흐름을 검증한다.
abstract class ScanSourcePort {
  /// 실제 선택 가능한지(패키지·권한 준비 여부).
  bool get isAvailable;

  /// 소스에서 이미지 1장 선택. 사용자 취소면 null.
  /// 허용되지 않는 파일(PDF 등)은 [AppError] 로 사용자 문구를 전달한다.
  Future<PickedImage?> pick(ScanSource source);
}

/// 운영 구현 — 촬영·갤러리는 image_picker, 파일은 file_picker.
class DeviceScanSourcePicker implements ScanSourcePort {
  const DeviceScanSourcePicker();

  @override
  bool get isAvailable => true;

  @override
  Future<PickedImage?> pick(ScanSource source) {
    switch (source) {
      case ScanSource.camera:
        return _pickWithImagePicker(ImageSource.camera);
      case ScanSource.gallery:
        return _pickWithImagePicker(ImageSource.gallery);
      case ScanSource.file:
        return _pickFile();
    }
  }

  /// 촬영/갤러리 공통 — 기존 품질 85 유지 + 장변 4096px 캡(§6-4 일원화).
  Future<PickedImage?> _pickWithImagePicker(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85, // 과도한 원본 크기 방지(5MB 제한과 함께).
      maxWidth: kScanMaxLongSidePx,
      maxHeight: kScanMaxLongSidePx,
    );
    if (file == null) return null; // 사용자 취소.
    return PickedImage(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType ?? scanMimeFromName(file.name),
    );
  }

  /// 파일 소스 — 이미지 + PDF 허용(FileType.custom, S19).
  /// PDF 는 그대로 [PickedImage] 로 반환 — 페이지 래스터화·선택은 상위
  /// 소스 계층(expandScanPick)이 담당한다(화면별 분기 금지).
  Future<PickedImage?> _pickFile() async {
    // file_picker 11.x: 정적 FilePicker.pickFiles (구 .platform 싱글턴 제거됨).
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: kScanFilePickerExtensions,
      withData: true, // 메모리 bytes 로 통일(PickedImage 계약).
    );
    final PlatformFile? file =
        (result == null || result.files.isEmpty) ? null : result.files.first;
    if (file == null) return null; // 사용자 취소.

    final String name = file.name;
    // 확장자 필터를 우회한 선택(플랫폼별 편차) 방어 — 미지원 확장자 일반 거부.
    final bool allowed = kScanFilePickerExtensions
        .any((String ext) => name.toLowerCase().endsWith('.$ext'));
    if (!allowed) {
      throw const AppError('이미지(JPG·PNG·WEBP·HEIC)나 PDF 파일만 올릴 수 있어요.');
    }
    if (file.bytes == null) {
      throw const AppError('파일을 읽지 못했어요. 다시 선택해 주세요.');
    }
    return PickedImage(
      bytes: file.bytes!,
      fileName: name,
      mimeType: scanMimeFromName(name),
    );
  }
}
