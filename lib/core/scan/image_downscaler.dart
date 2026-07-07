import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'picked_image.dart';

/// 업로드 전 초과 이미지 축소(§6-4: "5MB 초과 스캔은 업로드 전 리사이즈").
///
/// [maxBytes] 이하면 원본 그대로. 초과면 장변을 [maxLongSide] 로 캡해
/// **JPEG(품질 85)** 로 재인코딩한다 — 사진류에서 PNG 재인코딩이 오히려
/// 팽창하던 S16 방식(dart:ui)을 package:image(순수 Dart)로 교체(S17).
/// 투명 픽셀이 있는 이미지만 PNG 를 유지한다(JPEG 는 알파를 잃는다).
/// 재인코딩 결과가 여전히 초과이거나 디코드 실패면 **원본을 그대로 반환**
/// — 하류의 validatePickedImage 가 기존 한글 문구로 거부한다(작업 유실 없이 안내).
Future<PickedImage> downscaleIfOversized(
  PickedImage image, {
  int maxBytes = 5 * 1024 * 1024,
  int maxLongSide = 2560,
}) async {
  if (image.sizeBytes <= maxBytes) return image;
  try {
    final img.Image? decoded = img.decodeImage(image.bytes);
    if (decoded == null) return image; // 미지원 포맷 — 하류 검증이 안내.

    final int longSide =
        decoded.width >= decoded.height ? decoded.width : decoded.height;
    final img.Image resized = longSide <= maxLongSide
        ? decoded
        : (decoded.width >= decoded.height
            ? img.copyResize(decoded, width: maxLongSide)
            : img.copyResize(decoded, height: maxLongSide));

    final bool keepPng = _hasTransparency(resized);
    final Uint8List bytes = keepPng
        ? Uint8List.fromList(img.encodePng(resized))
        : Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    if (bytes.length > maxBytes) return image; // 축소로도 초과 → 하류 거부.

    return PickedImage(
      bytes: bytes,
      fileName: _withExt(image.fileName, keepPng ? 'png' : 'jpg'),
      mimeType: keepPng ? 'image/png' : 'image/jpeg',
    );
  } catch (_) {
    return image; // 어떤 실패든 원본 유지(하류 검증이 안내).
  }
}

/// 알파 채널에 실제 투명 픽셀이 있는지(불투명 알파만이면 JPEG 로 충분).
bool _hasTransparency(img.Image image) {
  if (!image.hasAlpha) return false;
  for (final img.Pixel p in image) {
    if (p.a < p.maxChannelValue) return true;
  }
  return false;
}

String _withExt(String name, String ext) {
  final int dot = name.lastIndexOf('.');
  return dot <= 0 ? '$name.$ext' : '${name.substring(0, dot)}.$ext';
}
