import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:ssambership_app/core/ink/ink_input_mode.dart';
import 'package:ssambership_app/core/ink/scribble_ink_adapter.dart';
import 'package:ssambership_app/core/ink/widgets/ink_toolbar.dart';

/// InkToolbar(P0) — 색·굵기·지우개·전체 지우기·손가락 토글의 notifier 반영 검증.
/// DB 미접촉, notifier 직접 주입.
void main() {
  /// inputMode 를 상위에서 갱신해 주는 테스트용 래퍼(실사용 화면과 동일 구조).
  /// splashFactory 는 NoSplash — 헤드리스 테스트에서 ink_sparkle 셰이더 로딩을 피한다.
  Widget wrap(ScribbleNotifier notifier) {
    InkInputMode mode = InkInputMode.penOnly; // 클로저에 보관해 리빌드에도 유지.
    return MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return InkToolbar(
              notifier: notifier,
              inputMode: mode,
              onInputModeChanged: (InkInputMode m) => setState(() => mode = m),
            );
          },
        ),
      ),
    );
  }

  Sketch oneLineSketch() => const Sketch(
        lines: <SketchLine>[
          SketchLine(
            points: <Point>[Point(0, 0), Point(1, 1)],
            color: 0xFF000000,
            width: 3,
          ),
        ],
      );

  testWidgets('툴바가 렌더되고 기본 버튼들이 보인다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(wrap(notifier));

    expect(find.byType(InkToolbar), findsOneWidget);
    expect(find.byTooltip('펜'), findsOneWidget);
    expect(find.byTooltip('지우개'), findsOneWidget);
    expect(find.byTooltip('빨강'), findsOneWidget);
    expect(find.byTooltip('전체 지우기'), findsOneWidget);
  });

  testWidgets('색 프리셋 선택 시 notifier 선택색이 바뀐다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(wrap(notifier));

    await tester.tap(find.byTooltip('빨강'));
    await tester.pump();

    final int selected = notifier.value.map(
      drawing: (Drawing d) => d.selectedColor,
      erasing: (_) => -1,
    );
    expect(selected, Colors.red.toARGB32());
  });

  testWidgets('굵기 선택 시 notifier 선택 굵기가 바뀐다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(wrap(notifier));

    await tester.tap(find.byTooltip('굵은 펜'));
    await tester.pump();

    expect(notifier.value.selectedWidth, 12);
  });

  testWidgets('지우개 토글 시 지우기 상태로 전환된다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(wrap(notifier));

    await tester.tap(find.byTooltip('지우개'));
    await tester.pump();

    final bool erasing = notifier.value.map(
      drawing: (_) => false,
      erasing: (_) => true,
    );
    expect(erasing, isTrue);
  });

  testWidgets('전체 지우기: 확인 다이얼로그 후에만 지워진다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    notifier.setSketch(sketch: oneLineSketch());
    await tester.pumpWidget(wrap(notifier));

    await tester.tap(find.byTooltip('전체 지우기'));
    await tester.pumpAndSettle();
    // 확인 다이얼로그 노출 — 아직 지워지지 않음.
    expect(find.text('필기 전체를 지울까요? 되돌릴 수 없어요.'), findsOneWidget);
    expect(notifier.currentSketch.lines, isNotEmpty);

    // 확인 버튼(다이얼로그 액션) 탭 → clear.
    await tester.tap(find.widgetWithText(TextButton, '전체 지우기'));
    await tester.pumpAndSettle();
    expect(notifier.currentSketch.lines, isEmpty);
  });

  testWidgets('전체 지우기: 취소 시 유지된다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    notifier.setSketch(sketch: oneLineSketch());
    await tester.pumpWidget(wrap(notifier));

    await tester.tap(find.byTooltip('전체 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();

    expect(notifier.currentSketch.lines, isNotEmpty);
  });

  testWidgets('손가락 토글 시 allowedPointers 모드가 all 로 바뀐다',
      (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(wrap(notifier));
    // 기본은 펜 전용.
    expect(notifier.value.allowedPointersMode, ScribblePointerMode.penOnly);

    await tester.tap(find.byTooltip('펜 전용'));
    await tester.pump();

    expect(notifier.value.allowedPointersMode, ScribblePointerMode.all);
  });
}
