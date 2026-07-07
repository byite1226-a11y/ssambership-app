import 'dart:typed_data';
import 'dart:ui' as ui;

import 'picked_image.dart';

/// 업로드 전 초과 이미지 축소(§6-4: "5MB 초과 스캔은 업로드 전 리사이즈").
///
/// [maxBytes] 이하면 원본 그대로. 초과면 장변을 [maxLongSide] 로 캡해
/// 다시 디코드하고 PNG 로 재인코딩한다(dart:ui 는 PNG 인코딩만 지원).
/// 재인코딩 결과가 여전히 초과이거나 디코드에 실패하면 **원본을 그대로 반환**
/// — 하류의 validatePickedImage 가 기존 한글 문구로 거부한다(작업 유실 없이 안내).
Future<PickedImage> downscaleIfOversized(
  PickedImage image, {
  int maxBytes = 5 * 1024 * 1024,
  int maxLongSide = 2560,
}) async {
  if (image.sizeBytes <= maxBytes) return image;
  try {
    // 1) 원본 크기 파악(타깃 없이 1회 디코드).
    final ui.Codec probe = await ui.instantiateImageCodec(image.bytes);
    final ui.FrameInfo probeFrame = await probe.getNextFrame();
    final int w = probeFrame.image.width;
    final int h = probeFrame.image.height;
    probeFrame.image.dispose();
    probe.dispose();
    if (w <= 0 || h <= 0) return image;

    // 2) 장변 기준 축소 재디코드(한 축만 지정 → 종횡비 보존).
    final ui.Codec codec = w >= h
        ? await ui.instantiateImageCodec(image.bytes,
            targetWidth: maxLongSide < w ? maxLongSide : w)
        : await ui.instantiateImageCodec(image.bytes,
            targetHeight: maxLongSide < h ? maxLongSide : h);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ByteData? png =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (png == null) return image;

    final Uint8List bytes = png.buffer.asUint8List();
    if (bytes.length > maxBytes) return image; // 축소로도 초과 → 하류 거부.
    return PickedImage(
      bytes: bytes,
      fileName: _withPngName(image.fileName),
      mimeType: 'image/png',
    );
  } catch (_) {
    return image; // 디코드 불가 포맷 등 — 원본 유지(하류 검증이 안내).
  }
}

String _withPngName(String name) {
  final int dot = name.lastIndexOf('.');
  return dot <= 0 ? '$name.png' : '${name.substring(0, dot)}.png';
}
