import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../../core/ink/ink_document.dart';
import '../../../core/ink/ink_input_mode.dart';
import '../../../core/ink/scribble_ink_adapter.dart';
import '../../../design/tokens/color_tokens.dart';
import 'ink_note_result.dart';
import 'widgets/ink_canvas.dart';
import 'widgets/ink_toolbar.dart';

/// 연결노트 필기 캔버스 화면(풀스크린).
///
/// ★ 소비 전용: 잉크 엔진 지식은 lib/core/ink/ 에 있고, 이 화면은 어댑터
///   (ScribbleInkAdapter)를 통해서만 생성/복원/내보내기를 한다.
/// ★ 저장 없음: '완료'는 InkDocument 를 [InkNoteResult] 로 돌려줄 뿐,
///   Storage 업로드는 S14-2 범위라 여기서 하지 않는다.
class InkNoteScreen extends StatefulWidget {
  const InkNoteScreen({
    super.key,
    required this.title,
    this.initial,
    @visibleForTesting this.notifierOverride,
  });

  /// AppBar 제목.
  final String title;

  /// 편집 진입 시 복원할 기존 문서. null 이면 새 필기(펜 전용 기본).
  final InkDocument? initial;

  /// 테스트 주입용 notifier. null 이면 어댑터로 생성/복원(운영 경로).
  @visibleForTesting
  final ScribbleNotifier? notifierOverride;

  @override
  State<InkNoteScreen> createState() => _InkNoteScreenState();
}

class _InkNoteScreenState extends State<InkNoteScreen> {
  late final ScribbleNotifier _notifier;

  /// 내보내기에 쓸 현재 입력 모드(툴바의 손가락 토글로 갱신).
  late InkInputMode _inputMode;

  /// 진입 직후 스케치 스냅샷 — '변경분 있음' 판정 기준.
  late String _initialSketchJson;

  /// 현재 필기가 진입 시점 대비 변경되었는지(스트로크 기준).
  bool _dirty = false;

  /// 캔버스 논리 크기(InkCanvas 가 측정해 전달).
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    final InkDocument? initial = widget.initial;
    _inputMode = initial?.inputMode ?? InkInputMode.penOnly;
    _notifier = widget.notifierOverride ??
        (initial != null
            ? ScribbleInkAdapter.restoreNotifier(initial)
            : ScribbleInkAdapter.createNotifier());
    _initialSketchJson = _sketchJson();
    _notifier.addListener(_onInkChanged);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onInkChanged);
    _notifier.dispose();
    super.dispose();
  }

  String _sketchJson() => jsonEncode(_notifier.currentSketch.toJson());

  /// 스트로크가 진입 시점과 달라졌을 때만 dirty 를 갱신(색·굵기 변경은 무시).
  void _onInkChanged() {
    final bool dirty = _sketchJson() != _initialSketchJson;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  void _onCanvasSize(Size size) => _canvasSize = size;

  void _onInputModeChanged(InkInputMode mode) =>
      setState(() => _inputMode = mode);

  /// '완료' — 문서를 내보내 결과로 pop. 빈 필기면 결과 없이 pop(null).
  void _onDone() {
    final InkDocument document = ScribbleInkAdapter.exportDocument(
      _notifier,
      canvasSize: _canvasSize,
      mode: _inputMode,
    );
    if (document.isEmpty) {
      Navigator.of(context).pop(); // 빈 필기: 결과 없이 닫는다.
      return;
    }
    Navigator.of(context).pop(
      InkNoteResult(document: document, modified: _dirty),
    );
  }

  /// 변경분이 있을 때 나가기 확인. 나가면 true.
  Future<bool> _confirmDiscard() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('나가기'),
        content: const Text('나가면 필기가 사라져요. 그래도 나갈까요?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 필기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // 변경분이 없으면 곧바로 나갈 수 있게 한다.
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool leave = await _confirmDiscard();
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: ColorTokens.page,
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            TextButton(
              onPressed: _onDone,
              child: const Text('완료'),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: InkCanvas(
                notifier: _notifier,
                onCanvasSize: _onCanvasSize,
              ),
            ),
            InkToolbar(
              notifier: _notifier,
              inputMode: _inputMode,
              onInputModeChanged: _onInputModeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
