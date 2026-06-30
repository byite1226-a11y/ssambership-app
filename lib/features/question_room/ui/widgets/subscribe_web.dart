import 'package:flutter/material.dart';

import '../../../web_bridge/web_bridge.dart';

/// 구독은 앱에서 결제하지 않고 '웹'에서만 진행한다(Commerce-Zero).
/// 웹 URL이 아직 미확정(S12 전)이면 안내만 노출하는 placeholder로 동작한다.
Future<void> openSubscribeWeb(BuildContext context) async {
  final bool opened = await WebBridge.openSubscribeOnWeb();
  if (opened) return;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('구독은 웹에서 진행돼요. (준비 중)')),
  );
}
