import 'package:flutter/material.dart';
import '../../design/widgets/empty_screen.dart';

/// 알림(빈 화면). 푸시 수신/목록은 후속.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(title: '알림');
  }
}
