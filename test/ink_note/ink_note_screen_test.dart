import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:ssambership_app/core/ink/scribble_ink_adapter.dart';
import 'package:ssambership_app/features/question_room/ink_note/ink_note_result.dart';
import 'package:ssambership_app/features/question_room/ink_note/ink_note_screen.dart';
import 'package:ssambership_app/features/question_room/ink_note/widgets/ink_canvas.dart';
import 'package:ssambership_app/features/question_room/ink_note/widgets/ink_toolbar.dart';

/// InkNoteScreen 스모크 + '완료'/뒤로가기 흐름.
/// renderImage 등 RepaintBoundary 의존 기능은 검증하지 않는다(범위 제외).
void main() {
  Sketch oneLineSketch() => const Sketch(
        lines: <SketchLine>[
          SketchLine(
            points: <Point>[Point(0, 0), Point(1, 1)],
            color: 0xFF000000,
            width: 3,
          ),
        ],
      );

  testWidgets('스모크: 캔버스와 툴바가 함께 렌더된다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: InkNoteScreen(title: '연결노트 필기', notifierOverride: notifier),
    ));
    await tester.pumpAndSettle();

    expect(find.text('연결노트 필기'), findsOneWidget);
    expect(find.byType(InkCanvas), findsOneWidget);
    expect(find.byType(InkToolbar), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets("빈 필기로 '완료' 시 결과 없이(null) pop 된다",
      (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    Object? captured;
    bool returned = false;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () async {
              captured = await Navigator.of(context).push<InkNoteResult>(
                MaterialPageRoute<InkNoteResult>(
                  builder: (_) => InkNoteScreen(
                    title: '연결노트 필기',
                    notifierOverride: notifier,
                  ),
                ),
              );
              returned = true;
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(captured, isNull); // 빈 필기 → 결과 없음.
  });

  testWidgets('변경 후 뒤로가기 시 확인 다이얼로그가 뜬다', (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: InkNoteScreen(title: '연결노트 필기', notifierOverride: notifier),
    ));
    await tester.pumpAndSettle();

    // 스트로크 주입 → 변경분 발생.
    notifier.setSketch(sketch: oneLineSketch());
    await tester.pump();

    // 시스템 back → PopScope 가 가로채 확인 다이얼로그 노출.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('나가면 필기가 사라져요. 그래도 나갈까요?'), findsOneWidget);
  });

  testWidgets('변경 없으면 뒤로가기 시 확인 다이얼로그 없이 나간다',
      (WidgetTester tester) async {
    final ScribbleNotifier notifier = ScribbleInkAdapter.createNotifier();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: InkNoteScreen(title: '연결노트 필기', notifierOverride: notifier),
    ));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('나가면 필기가 사라져요. 그래도 나갈까요?'), findsNothing);
  });
}
