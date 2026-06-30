import 'package:flutter/material.dart';
import '../design/theme.dart';
import '../shared/constants/app_constants.dart';
import 'router.dart';

/// 루트 앱: 테마 + 라우터.
class SsambershipApp extends StatelessWidget {
  const SsambershipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      routerConfig: AppRouter.router,
    );
  }
}
