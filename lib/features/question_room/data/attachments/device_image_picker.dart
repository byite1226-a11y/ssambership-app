import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'attachment_upload.dart';

/// 실제 기기 갤러리 이미지 선택기(image_picker 기반).
///
/// 선택 자체는 즉시 동작한다. 업로드는 [AttachmentUploaderPort] 가 담당하며,
/// Storage 버킷이 준비되기 전에는 업로더가 graceful 하게 "준비 중"을 안내한다
/// (선택 → 미리보기까지는 되고, 저장만 버킷 준비에 의존).
class DeviceImagePicker implements ImagePickerPort {
  const DeviceImagePicker();

  @override
  bool get isAvailable => true;

  @override
  Future<PickedImage?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // 과도한 원본 크기 방지(5MB 제한과 함께).
    );
    if (file == null) return null; // 사용자 취소.
    final Uint8List bytes = await file.readAsBytes();
    final String name = file.name;
    final String mime = file.mimeType ?? _mimeFromName(name);
    return PickedImage(bytes: bytes, fileName: name, mimeType: mime);
  }

  /// XFile.mimeType 이 null 인 플랫폼 대비 — 확장자로 추론(허용목록 기준).
  static String _mimeFromName(String name) {
    final String n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg'; // jpg/jpeg 및 기타 기본.
  }
}
