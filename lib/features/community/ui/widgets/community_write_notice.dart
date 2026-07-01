import 'package:flutter/material.dart';

/// 글·숏폼 '작성'은 앱에서 하지 않는다(웹 전용). 앱은 안내만 노출한다.
/// ★ 앱 내 작성 화면을 만들지 않는다(읽기 + 반응만).
void showWriteOnWebNotice(BuildContext context, {bool shortform = false}) {
  final String what = shortform ? '숏폼' : '글';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$what 작성은 웹에서 할 수 있어요. (준비 중)')),
  );
}
