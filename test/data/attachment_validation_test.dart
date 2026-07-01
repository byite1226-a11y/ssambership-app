import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/question_room/data/attachments/attachment_upload.dart';

PickedImage _img({int size = 1000, String mime = 'image/png'}) => PickedImage(
      bytes: Uint8List(size),
      fileName: 'a.png',
      mimeType: mime,
    );

void main() {
  test('정상 이미지 → null(통과)', () {
    expect(validatePickedImage(_img()), isNull);
  });

  test('5MB 초과 → 크기 사유', () {
    final String? e = validatePickedImage(_img(size: kMaxAttachmentBytes + 1));
    expect(e, isNotNull);
    expect(e, contains('5MB'));
  });

  test('허용 안 되는 형식 → 형식 사유', () {
    final String? e = validatePickedImage(_img(mime: 'application/pdf'));
    expect(e, isNotNull);
  });

  test('업로드 제한 안내 문구는 저작권 안내를 포함하고 비어있지 않다', () {
    expect(kAttachmentRestrictionText, contains('저작권'));
    expect(kAttachmentRestrictionText.isNotEmpty, true);
  });

  test('DisabledImagePicker: 비활성 + null 반환(인수인계)', () async {
    const DisabledImagePicker p = DisabledImagePicker();
    expect(p.isAvailable, false);
    expect(await p.pickImage(), isNull);
  });

  test('SupabaseAttachmentUploader: 저장소 미준비(버킷 인수인계)', () {
    expect(const SupabaseAttachmentUploader().isReady, false);
  });
}
