import 'package:flutter/material.dart';

import '../../design/tokens/color_tokens.dart';
import '../../design/typography_tokens.dart';
import '../../design/widgets/primary_button.dart';
import '../../design/widgets/secondary_button.dart';
import '../../design/widgets/status_pill.dart';
import '../../design/widgets/app_badge.dart';
import '../../design/widgets/initial_avatar.dart';
import '../../design/widgets/app_card.dart';
import '../../design/widgets/slide_over_panel.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/skeleton.dart';
import '../../design/widgets/chip_scroll.dart';
import '../../design/widgets/quota_text.dart';

/// 개발 전용 위젯 갤러리. 공통 위젯을 상태별로 한눈에 본다.
/// ★ dev 전용 — 출시 빌드에서는 라우트가 등록되지 않는다(dev_flags / router 분기).
class WidgetGallery extends StatefulWidget {
  const WidgetGallery({super.key});

  @override
  State<WidgetGallery> createState() => _WidgetGalleryState();
}

class _WidgetGalleryState extends State<WidgetGallery> {
  int _chipIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('위젯 갤러리 (개발용)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _section('버튼 — 액션은 스카이(멘토 화면이라도 동일)'),
          const PrimaryButton(label: '확인'),
          const SizedBox(height: 10),
          const PrimaryButton(label: '비활성', onPressed: null),
          const SizedBox(height: 10),
          PrimaryButton(label: '아이콘', icon: Icons.send_rounded, onPressed: () {}),
          const SizedBox(height: 10),
          SecondaryButton(label: '취소', onPressed: () {}),
          const SizedBox(height: 10),
          const SecondaryButton(label: '비활성', onPressed: null),

          _section('역할색: 학생 파랑·멘토 초록(AppAccent)'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('멘토 · 질문방', style: AppType.caption),
                const SizedBox(height: 10),
                PrimaryButton(label: '답변 등록', onPressed: () {}),
              ],
            ),
          ),

          _section('StatusPill — 상태별(시맨틱 토큰)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              StatusPill(label: '답변대기', tone: StatusTone.warning),
              StatusPill(label: '진행중', tone: StatusTone.info),
              StatusPill(label: '답변완료', tone: StatusTone.success),
              StatusPill(label: '분쟁', tone: StatusTone.danger),
              StatusPill(label: '종료', tone: StatusTone.neutral),
            ],
          ),

          _section('Badge — 과목/플랜(한글 라벨만)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              AppBadge(label: '미적분', tinted: true),
              AppBadge(label: '확률과 통계'),
              AppBadge(label: '스탠다드', tinted: true),
            ],
          ),

          _section('InitialAvatar — 사진 없음(이니셜)'),
          Row(
            children: const <Widget>[
              InitialAvatar(name: '김멘토'),
              SizedBox(width: 12),
              InitialAvatar(name: '이학생', tinted: false),
              SizedBox(width: 12),
              InitialAvatar(name: 'A', size: 56),
              SizedBox(width: 12),
              InitialAvatar(name: '', size: 56), // 빈 이름 → '?'
            ],
          ),

          _section('QuotaText — "잔여 N개"(0/4 아님)'),
          Row(
            children: const <Widget>[
              QuotaText(remaining: 3),
              SizedBox(width: 16),
              QuotaText(remaining: 0, emphasize: false),
            ],
          ),

          _section('ChipScroll — 멘토 전환 칩(가로 스크롤)'),
          ChipScroll(
            labels: const <String>['전체', '김멘토', '박멘토', '최멘토', '정멘토', '한멘토'],
            selectedIndex: _chipIndex,
            onSelected: (int i) => setState(() => _chipIndex = i),
          ),

          _section('AppCard'),
          AppCard(
            onTap: () {},
            child: Row(
              children: const <Widget>[
                InitialAvatar(name: '김멘토'),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('카드 제목', style: AppType.body),
                      SizedBox(height: 4),
                      Text('탭 가능한 카드', style: AppType.caption),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: ColorTokens.muted),
              ],
            ),
          ),

          _section('Skeleton — 로딩 자리표시'),
          const Skeleton(width: 180, height: 18),
          const SizedBox(height: 8),
          const Skeleton(width: 120, height: 14),
          const SizedBox(height: 8),
          const Skeleton(height: 60, radius: 14),

          _section('SlideOverPanel — 우측 패널(연결노트/학생정보)'),
          SecondaryButton(
            label: '패널 열기',
            onPressed: () => SlideOverPanel.show(
              context,
              title: '연결노트',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text('학생 학습 메모(예시)', style: AppType.body),
                  SizedBox(height: 8),
                  Text('우측에서 슬라이드되는 패널입니다.',
                      style: AppType.caption),
                ],
              ),
            ),
          ),

          _section('EmptyState — 의미 있는 안내 + 액션'),
          SizedBox(
            height: 240,
            child: EmptyState(
              icon: Icons.forum_rounded,
              title: '아직 질문이 없어요',
              message: '궁금한 문제를 멘토에게 물어보세요.',
              actionLabel: '질문 시작하기',
              onAction: () {},
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(title, style: AppType.caption),
    );
  }
}
