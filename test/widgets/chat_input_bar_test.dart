import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/attachments/attachment_upload.dart';
import 'package:ssambership_app/features/question_room/ui/widgets/chat_input_bar.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('첨부 버튼 탭 → onAttach 콜백 연결', (WidgetTester tester) async {
    int attach = 0;
    await tester.pumpWidget(_wrap(ChatInputBar(
      controller: TextEditingController(),
      hintText: '메시지 입력',
      sending: false,
      onSend: () {},
      onAttach: () => attach++,
    )));
    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pump();
    expect(attach, 1);
  });

  testWidgets('전송 버튼 탭 → onSend 콜백', (WidgetTester tester) async {
    int send = 0;
    await tester.pumpWidget(_wrap(ChatInputBar(
      controller: TextEditingController(),
      hintText: '메시지 입력',
      sending: false,
      onSend: () => send++,
      onAttach: () {},
    )));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(send, 1);
  });

  testWidgets('선택 이미지 → 미리보기(파일명)·업로드 제한문구·제거 버튼',
      (WidgetTester tester) async {
    int removed = 0;
    final PickedImage img = PickedImage(
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      fileName: '문제사진.png',
      mimeType: 'image/png',
    );
    await tester.pumpWidget(_wrap(ChatInputBar(
      controller: TextEditingController(),
      hintText: '메시지 입력',
      sending: false,
      onSend: () {},
      onAttach: () {},
      pendingImage: img,
      onRemovePending: () => removed++,
    )));
    await tester.pump();

    expect(find.text('문제사진.png'), findsOneWidget);
    expect(find.textContaining('저작권'), findsOneWidget); // 업로드 제한 문구
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(removed, 1);
  });

  testWidgets('전송 중이면 전송 버튼 비활성(onSend 미호출)',
      (WidgetTester tester) async {
    int send = 0;
    await tester.pumpWidget(_wrap(ChatInputBar(
      controller: TextEditingController(),
      hintText: '메시지 입력',
      sending: true,
      onSend: () => send++,
      onAttach: () {},
    )));
    await tester.tap(find.byIcon(Icons.send), warnIfMissed: false);
    await tester.pump();
    expect(send, 0);
  });
}
