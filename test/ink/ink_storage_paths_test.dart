import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/ink/ink_input_mode.dart';
import 'package:ssambership_app/core/ink/ink_storage_paths.dart';

/// Storage 경로 규약 + 입력 모드 코드 — 형식 고정 회귀 방어.
void main() {
  test('연결노트 필기: 원본 JSON 과 썸네일이 같은 폴더·다른 파일로 분리된다', () {
    expect(
      InkStoragePaths.noteDocument('room-1', 'note-9'),
      'ink-notes/room-1/note-9/ink.json',
    );
    expect(
      InkStoragePaths.noteThumbnail('room-1', 'note-9'),
      'ink-notes/room-1/note-9/thumb.png',
    );
  });

  test('스캔 주석(S15): 원본과 평탄화 출력 경로', () {
    expect(
      InkStoragePaths.annotationDocument('room-1', 'att-3'),
      'ink-annotations/room-1/att-3/ink.json',
    );
    expect(
      InkStoragePaths.annotationFlattened('room-1', 'att-3'),
      'ink-annotations/room-1/att-3/flat.png',
    );
  });

  test('빈 ID·구분자 포함 ID 는 ArgumentError', () {
    expect(() => InkStoragePaths.noteDocument('', 'n'), throwsArgumentError);
    expect(() => InkStoragePaths.noteDocument('a/b', 'n'), throwsArgumentError);
    expect(() => InkStoragePaths.noteDocument('a', '..'), throwsArgumentError);
  });

  test('입력 모드 code 왕복 + 알 수 없는 값은 펜 전용', () {
    for (final InkInputMode mode in InkInputMode.values) {
      expect(InkInputModeLabel.fromCode(mode.code), mode);
    }
    expect(InkInputModeLabel.fromCode(null), InkInputMode.penOnly);
    expect(InkInputModeLabel.fromCode('???'), InkInputMode.penOnly);
  });

  test('화면 라벨은 한글(내부 코드값 노출 금지 원칙)', () {
    expect(InkInputMode.penOnly.label, '펜 전용');
    expect(InkInputMode.penAndTouch.label, '손가락 허용');
  });
}
