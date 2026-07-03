import 'package:flutter/material.dart';
import '../role_accent.dart';
import '../typography_tokens.dart';
import 'primary_button.dart';

/// 빈 상태(D-4): 아이콘 + 문구 + (선택) 액션. ★순수 프리젠테이션 위젯(로직 없음)★.
/// ★ '준비 중' 같은 미완성 문구를 쓰지 않는다 — 사용자에게 의미 있는 안내/행동을 준다.
///
/// 구성: (옅은 role accent 원형 배경 안) Material 표준 아이콘 46px → 제목 → 본문(보조색)
///       → CTA(role accent PrimaryButton; label+콜백 있을 때만). ★큰 일러스트/캐릭터 없음.★
/// 색은 [AppAccent](역할색, 학생 파랑/멘토 초록 자동)·토큰만 사용(raw hex 금지).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final RoleAccent ra = AppAccent.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 옅은 역할색 원형 배경 + 표준 아이콘(46). 장식 이미지 아님.
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: ra.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: ra.accent),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppType.title, textAlign: TextAlign.center),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(message!,
                  style: AppType.caption, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
