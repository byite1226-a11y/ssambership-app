import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/entry_guard.dart';
import '../../core/auth/auth_service.dart';
import '../../design/spacing_tokens.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/typography_tokens.dart';
import '../dev/dev_flags.dart';
import 'data/mypage_models.dart';
import 'data/mypage_repository.dart';
import 'ui/profile_edit_screen.dart';
import 'ui/sections/cash_section.dart';
import 'ui/sections/individual_question_section.dart';
import 'ui/sections/mentor_dashboard_section.dart';
import 'ui/sections/profile_section.dart';
import 'ui/sections/settings_section.dart';
import 'ui/sections/student_subscription_section.dart';
import 'ui/sections/support_section.dart';

/// 마이페이지(보강) — 조회 중심 대시보드. role(student/mentor)별로 내용이 다르다.
/// ★ Commerce-Zero: 결제·충전·정산 출금은 앱에서 실행하지 않고 '웹'으로만 연결한다.
///   기존 S2(이름·역할·로그아웃)를 설정 섹션으로 통합한다.
///
/// HomeShell 이 AppBar/하단탭을 제공하므로 본문만 구성(자체 Scaffold 없음).
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({
    super.key,
    this.loaderOverride,
    this.onOpenQuestionsTab,
  });

  /// 테스트용 데이터 주입(실제 DB·네트워크 대신 mock). null 이면 실제 레포 사용.
  final Future<MyPageData> Function()? loaderOverride;

  /// '질문하러 가기' 등에서 질문방 탭으로 보내는 핸드오프(없으면 안내).
  /// TODO(S11): HomeShell 탭 상태가 노출되면 실제 탭 전환으로 연결.
  final VoidCallback? onOpenQuestionsTab;

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final MyPageRepository _repo = const MyPageRepository();
  late Future<MyPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = (widget.loaderOverride ?? _repo.load)();
  }

  Future<void> _openProfileEdit(MyProfile profile) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProfileEditScreen(profile: profile),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _future = (widget.loaderOverride ?? _repo.load)());
    }
  }

  void _goToQuestions() {
    if (widget.onOpenQuestionsTab != null) {
      widget.onOpenQuestionsTab!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('질문방 탭에서 질문할 수 있어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<MyPageData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<MyPageData> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('내 정보를 불러오지 못했어요.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ColorTokens.danger)),
              ),
            );
          }
          return _body(snap.data!);
        },
      ),
    );
  }

  Widget _body(MyPageData data) {
    final bool signedIn = AuthService.instance.isSignedIn;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.s16, 20, AppSpacing.s24),
      children: <Widget>[
        ProfileSection(
          profile: data.profile,
          // 게스트(비로그인)는 수정 불가 — 세션 있을 때만 수정 진입 노출.
          onEdit: AuthService.instance.isSignedIn
              ? () => _openProfileEdit(data.profile)
              : null,
        ),
        const SizedBox(height: AppSpacing.section),
        if (data.isMentor)
          ..._mentorSections(data)
        else
          ..._studentSections(data),
        SettingsSection(
          onLogout: () => AuthService.instance.signOut(),
          showLogout: signedIn,
        ),
        if (kDevToolsEnabled) ...<Widget>[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => context.go(EntryGuard.devS3),
              child: Text('S3 데이터 점검 (개발용)',
                  style: AppType.caption),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _studentSections(MyPageData data) {
    return <Widget>[
      StudentSubscriptionSection(
        subscriptions: data.subscriptions,
        onGoToQuestions: _goToQuestions,
      ),
      const IndividualQuestionSection(isMentor: false),
      if (data.cash != null) CashSection(cash: data.cash!),
      const SupportSection(),
    ];
  }

  List<Widget> _mentorSections(MyPageData data) {
    return <Widget>[
      if (data.mentor != null)
        MentorDashboardSection(
          data: data.mentor!,
          onGoToQuestions: _goToQuestions,
        ),
      const IndividualQuestionSection(isMentor: true),
      const SupportSection(),
    ];
  }
}
