import 'package:flutter/material.dart';

import '../../../web_bridge/web_bridge.dart';

/// '구독하기' = 웹 브릿지로 웹 구독 페이지를 연다.
///
/// ★ Commerce-Zero: 앱에서 결제하지 않는다. 가격/요금제는 '표시'만 하고,
///   실제 구독은 웹에서 진행한다. 웹 URL 미확정(S12 전)이면 열지 않고 안내만 한다.
Future<void> openMentorSubscribeWeb(BuildContext context) async {
  final bool opened = await WebBridge.openSubscribeOnWeb();
  if (opened) return;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('구독은 웹에서 진행돼요. (준비 중)')),
  );
}
