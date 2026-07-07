import '../../../../core/scan/scan_source_picker.dart';
import 'attachment_upload.dart';

/// 실제 기기 갤러리 이미지 선택기 — S16부터 [DeviceScanSourcePicker] 위임 래퍼.
///
/// 하위호환용으로 유지한다(기존 호출부·주입 시그니처 불변). 갤러리 결과는
/// 새 포트와 동일 규약(품질 85 + 장변 4096px 캡, §6-4 일원화)을 따른다.
/// 촬영·파일 소스는 [ScanSourcePort] 를 직접 쓴다.
class DeviceImagePicker implements ImagePickerPort {
  const DeviceImagePicker();

  @override
  bool get isAvailable => true;

  @override
  Future<PickedImage?> pickImage() =>
      const DeviceScanSourcePicker().pick(ScanSource.gallery);
}
