import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

import '../../shared/errors/app_error.dart';

/// PDF 열기 실패(암호화·손상·0페이지) 폴백 안내(§6-4).
const String kScanPdfOpenFailedText =
    '이 PDF는 열 수 없어요. 촬영하거나 이미지로 올려 주세요.';

/// 페이지 본렌더 장변(픽셀). 2560 인 이유:
/// ① §6-4 크기 규약과 수렴 — 5MB 초과 시 downscaleIfOversized 가 어차피
///   장변 2560·JPEG 품질85 로 재인코딩한다. 더 크게(4096) 렌더해도 대부분
///   이중 리사이즈로 버려지고 PNG 메모리 피크(A4 350DPI ≈ 40MB+)만 커진다.
/// ② A4(약 8.3in) 기준 2560px ≈ 300DPI 급 — 문제지 본문(9pt+) 가독 충분.
const double kPdfRenderLongSidePx = 2560;

/// 페이지 선택 그리드 썸네일 장변(지연 렌더 — 메모리 보호).
const double kPdfThumbLongSidePx = 320;

/// 1회 선택 최대 페이지 수(§6-1 — 페이지당 1첨부, 최대 5페이지/회).
const int kPdfMaxPagesPerPick = 5;

/// 열린 PDF 문서 핸들 — 페이지 수 + 페이지별 지연 렌더.
///
/// ★ 지연 렌더 규약: 썸네일이든 본렌더든 호출 시점에 페이지 1장만 렌더한다
///   (50페이지 문제집을 통째로 렌더하지 않는다 — §6-4 메모리 보호).
abstract class PdfDocumentHandle {
  int get pageCount;

  /// [pageIndex] 는 0-기준. 비율 유지로 장변을 [longSide] 픽셀에 맞춰
  /// PNG bytes 로 렌더한다. 실패 시 [AppError] (사용자 문구).
  Future<Uint8List> renderPage(int pageIndex, {required double longSide});

  /// 네이티브 문서 자원 해제(호출부 책임 — try/finally).
  Future<void> close();
}

/// PDF 래스터라이저 포트(S19). 테스트는 fake 를 주입한다
/// (네이티브 렌더는 헤드리스 불가 — 실렌더 검증은 실기기 QA 항목).
abstract class PdfRasterizerPort {
  /// 플랫폼 렌더러 준비 여부.
  bool get isAvailable;

  /// PDF bytes 를 연다. 암호화·손상·0페이지면 [AppError]
  /// ([kScanPdfOpenFailedText]) — 원문 에러 비노출 규약.
  Future<PdfDocumentHandle> open(Uint8List bytes);
}

/// pdfx 구현 — Android/iOS 네이티브 렌더(pdfium/CoreGraphics).
class PdfxRasterizer implements PdfRasterizerPort {
  const PdfxRasterizer();

  @override
  bool get isAvailable => true;

  @override
  Future<PdfDocumentHandle> open(Uint8List bytes) async {
    final PdfDocument document;
    try {
      document = await PdfDocument.openData(bytes);
    } catch (_) {
      // 암호화(비밀번호)·손상 등 — 세부 사유 구분 없이 촬영/이미지 폴백 안내.
      throw const AppError(kScanPdfOpenFailedText);
    }
    if (document.pagesCount <= 0) {
      await document.close();
      throw const AppError(kScanPdfOpenFailedText);
    }
    return _PdfxDocumentHandle(document);
  }
}

class _PdfxDocumentHandle implements PdfDocumentHandle {
  _PdfxDocumentHandle(this._document);

  final PdfDocument _document;

  @override
  int get pageCount => _document.pagesCount;

  @override
  Future<Uint8List> renderPage(
    int pageIndex, {
    required double longSide,
  }) async {
    final PdfPage page = await _document.getPage(pageIndex + 1); // 1-기준.
    try {
      final double pageLong =
          page.width >= page.height ? page.width : page.height;
      final double scale = pageLong <= 0 ? 1 : longSide / pageLong;
      final PdfPageImage? image = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF', // 투명 페이지 → 흰 종이 배경.
      );
      if (image == null) throw const AppError(kScanPdfOpenFailedText);
      return image.bytes;
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(kScanPdfOpenFailedText);
    } finally {
      await page.close();
    }
  }

  @override
  Future<void> close() => _document.close();
}
