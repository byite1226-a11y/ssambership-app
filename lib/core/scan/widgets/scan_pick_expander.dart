import 'package:flutter/material.dart';

import '../../../shared/errors/app_error.dart';
import '../pdf_rasterizer.dart';
import '../picked_image.dart';
import 'pdf_page_select_screen.dart';

/// 소스 선택 결과 1건 → 이미지 첨부 목록(S19 소스 계층 공통 처리).
///
/// - 이미지: 그대로 1장.
/// - PDF: 래스터라이저로 열어 페이지 선택 그리드(다중, 최대
///   [kPdfMaxPagesPerPick] 와 [maxCount] 중 작은 값) → 페이지당 1장.
///   1페이지짜리는 그리드 없이 바로 렌더(고를 게 없다).
///   암호화·손상·0페이지는 [AppError] (촬영/이미지 폴백 안내 §6-4).
/// - null(취소)·그리드 취소: 빈 목록.
///
/// ★ 화면별 분기 금지 규약: 호출부(채팅·멘토 답변·IQ 작성)는 PDF 여부를
///   모른다 — 남은 슬롯 수([maxCount])만 넘기고 목록을 받아 기존 이미지
///   파이프라인(downscale→검증)에 태운다.
Future<List<PickedImage>> expandScanPick(
  BuildContext context, {
  required PickedImage? picked,
  required PdfRasterizerPort rasterizer,
  required int maxCount,
}) async {
  if (picked == null || maxCount <= 0) return const <PickedImage>[];
  if (!isPdfPickedImage(picked)) return <PickedImage>[picked];

  final PdfDocumentHandle document = await rasterizer.open(picked.bytes);
  try {
    if (document.pageCount <= 0) {
      // 구현이 놓친 0페이지 방어(이중 방어 — PdfxRasterizer 도 자체 거부).
      throw const AppError(kScanPdfOpenFailedText);
    }
    final String baseName = _withoutExt(picked.fileName);
    if (document.pageCount == 1) {
      return <PickedImage>[
        PickedImage(
          bytes: await document.renderPage(0,
              longSide: kPdfRenderLongSidePx),
          fileName: '$baseName-p1.png',
          mimeType: 'image/png',
        ),
      ];
    }
    if (!context.mounted) return const <PickedImage>[];
    final List<PickedImage>? pages =
        await Navigator.of(context).push<List<PickedImage>>(
      MaterialPageRoute<List<PickedImage>>(
        builder: (BuildContext context) => PdfPageSelectScreen(
          document: document,
          baseName: baseName,
          maxSelect:
              maxCount < kPdfMaxPagesPerPick ? maxCount : kPdfMaxPagesPerPick,
        ),
      ),
    );
    return pages ?? const <PickedImage>[]; // 그리드 취소 = 무동작.
  } finally {
    await document.close();
  }
}

String _withoutExt(String name) {
  final int dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}
