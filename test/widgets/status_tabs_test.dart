import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/design/widgets/chip_scroll.dart';

/// 멘토 질문 목록(S5)의 ★고유★ 상태 탭(답변 대기 / 진행 중 / 완료) 구조 검증.
/// 화면이 레포 의존이라, 탭을 구성하는 ChipScroll 에 같은 라벨을 넣어 렌더/전환을 본다.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('상태 탭 3종(대기/진행/완료)이 모두 렌더된다',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChipScroll(
        labels: const <String>['답변 대기 2', '진행 중 1', '완료 1'],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
    ));
    expect(find.textContaining('답변 대기'), findsOneWidget);
    expect(find.textContaining('진행 중'), findsOneWidget);
    expect(find.textContaining('완료'), findsOneWidget);
  });

  testWidgets('탭 선택 콜백이 인덱스를 전달한다', (WidgetTester tester) async {
    int? picked;
    await tester.pumpWidget(_wrap(
      ChipScroll(
        labels: const <String>['답변 대기 2', '진행 중 1', '완료 1'],
        selectedIndex: 0,
        onSelected: (int i) => picked = i,
      ),
    ));
    await tester.tap(find.textContaining('진행 중'));
    await tester.pump();
    expect(picked, 1);
  });
}
