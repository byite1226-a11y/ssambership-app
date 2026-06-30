import 'package:flutter/material.dart';

import '../../../web_bridge/web_bridge.dart';

/// 결제·충전·결제관리는 앱에서 실행하지 않는다(Commerce-Zero). 웹으로만 연결한다.
/// 웹 URL 이 아직 미확정(S12 전)이면 안내 스낵바만 띄우는 placeholder 로 동작한다.

/// 캐시 충전 — 웹에서.
Future<void> openWalletChargeWeb(BuildContext context) async {
  final bool opened = await WebBridge.openWalletChargeOnWeb();
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('충전은 웹에서 진행돼요. (준비 중)')),
  );
}

/// 결제·구독 관리 — 웹에서.
Future<void> openManagePaymentsWeb(BuildContext context) async {
  final bool opened = await WebBridge.openSubscribeOnWeb();
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('결제·구독 관리는 웹에서 할 수 있어요. (준비 중)')),
  );
}
