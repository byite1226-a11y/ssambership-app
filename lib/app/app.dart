import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../design/theme.dart';
import '../shared/constants/app_constants.dart';
import 'router.dart';

/// 루트 앱: 테마 + 라우터.
///
/// 테마는 현재 로그인 역할(AuthService.currentRole)에 따라 강조색이 분기된다
/// (학생/공개=파랑, 멘토=초록). role 변화(로그인/로그아웃) 시 테마가 재빌드된다.
class SsambershipApp extends StatelessWidget {
  const SsambershipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp.router(
          title: AppConstants.appDisplayName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(AuthService.instance.currentRole),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
