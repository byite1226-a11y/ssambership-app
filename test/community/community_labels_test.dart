import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/features/community/data/community_labels.dart';

/// 카테고리 코드(영문) → 한글 라벨(순수). 화면에 영문 코드 노출 금지.
void main() {
  test('실제 DB 값 → 한글 라벨', () {
    expect(communityCategoryLabel('study'), '학습');
    expect(communityCategoryLabel('school'), '내신');
    expect(communityCategoryLabel('free'), '자유');
    expect(communityCategoryLabel('college'), '대학생활');
    expect(communityCategoryLabel('career'), '진로');
  });

  test('빈/미정 코드는 "기타"로 폴백(코드 노출 없음)', () {
    expect(communityCategoryLabel(null), '기타');
    expect(communityCategoryLabel(''), '기타');
    expect(communityCategoryLabel('unknown_code'), '기타');
  });

  test('필터 옵션은 5개 실제 카테고리', () {
    expect(communityCategoryOptions.length, 5);
    expect(communityCategoryOptions.map((e) => e.value).toList(),
        <String>['학습', '내신', '자유', '대학생활', '진로']);
  });
}
