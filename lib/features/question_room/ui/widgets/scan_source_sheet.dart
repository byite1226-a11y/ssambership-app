import 'package:flutter/material.dart';

import '../../../../core/scan/scan_source_picker.dart';
import '../../../../design/typography_tokens.dart';

/// 스캔 소스 선택 바텀시트(§6-1) — 촬영 / 갤러리 / 파일 3택.
///
/// 취소는 바깥 탭·아래로 드래그로 즉시(기본 dismiss 동작 유지 — 별도 버튼 없이
/// 한 손 흐름). 선택하면 해당 [ScanSource] 로 pop, 취소면 null.
Future<ScanSource?> showScanSourceSheet(BuildContext context) {
  return showModalBottomSheet<ScanSource>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => const SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SourceTile(
            icon: Icons.photo_camera_rounded,
            label: '촬영',
            caption: '카메라로 문제를 찍어서 올려요',
            source: ScanSource.camera,
          ),
          _SourceTile(
            icon: Icons.photo_library_rounded,
            label: '갤러리',
            caption: '저장된 사진에서 골라요',
            source: ScanSource.gallery,
          ),
          _SourceTile(
            icon: Icons.folder_rounded,
            label: '파일',
            caption: 'JPG·PNG·WEBP·HEIC 이미지 파일',
            source: ScanSource.file,
          ),
          SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.source,
  });

  final IconData icon;
  final String label;
  final String caption;
  final ScanSource source;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: AppType.body),
      subtitle: Text(caption, style: AppType.caption),
      onTap: () => Navigator.of(context).pop(source),
    );
  }
}
