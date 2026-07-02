import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/ink/ink_input_mode.dart';
import 'package:ssambership_app/core/ink/ink_storage_paths.dart';

/// Storage 경로 규약 + 입력 모드 코드 — 형식 고정 회귀 방어.
void main() {
  test('버킷 상수(정책 정합): 필기·주석 버킷 이름', () {
    expect(InkStoragePaths.bucket, 'connection-note-ink');
    expect(InkStoragePaths.annotationBucket, 'scan-annotations');
  });

  test('연결노트 필기: 첫 세그먼트=roomId, 작성자별로 원본·썸네일 분리(버킷 상대)', () {
    // 정책 통과 조건: 경로 첫 세그먼트가 room UUID.
    expect(
      InkStoragePaths.noteDocument('room-1', 'author-9'),
      'room-1/author-9/ink.json',
    );
    expect(
      InkStoragePaths.noteThumbnail('room-1', 'author-9'),
      'room-1/author-9/thumb.png',
    );
  });

  test('스캔 주석(S15): 원본과 평탄화 출력 경로(버킷 상대)', () {
    expect(
      InkStoragePaths.annotationDocument('room-1', 'att-3'),
      'room-1/att-3/ink.json',
    );
    expect(
      InkStoragePaths.annotationFlattened('room-1', 'att-3'),
      'room-1/att-3/flat.png',
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
