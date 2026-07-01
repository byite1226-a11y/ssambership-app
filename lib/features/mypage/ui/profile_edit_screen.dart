import 'package:flutter/material.dart';

import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/primary_button.dart';
import '../data/mypage_models.dart';
import '../data/profile_edit_repository.dart';

/// 프로필 수정 — 안전 필드(표시명·학년)만 편집. 역할·이메일·id 는 편집 대상 아님(표시만/제외).
/// ★ 프로필 이미지는 Storage 버킷 의존이라 이번 범위 밖(버킷 준비 후 별도) — 텍스트 필드는 즉시 작동.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.profile,
    this.repository = const ProfileEditRepository(),
  });

  final MyProfile profile;
  final ProfileEditRepository repository;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.name);
  late final TextEditingController _grade =
      TextEditingController(text: widget.profile.grade ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _grade.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final String grade = _grade.text.trim();
    if (name.isEmpty) {
      _snack('표시명을 입력해 주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.updateProfile(
        nickname: name,
        gradeLevel: grade.isEmpty ? null : grade,
      );
      if (!mounted) return;
      _snack('프로필을 저장했어요.');
      Navigator.of(context).pop(true); // 저장됨 → 마이페이지가 새로고침.
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('저장에 실패했어요. ($e)');
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('표시명', style: AppTypography.caption),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            style: AppTypography.body,
            decoration: _decoration('표시할 이름'),
          ),
          const SizedBox(height: 16),
          Text('학년 (선택)', style: AppTypography.caption),
          const SizedBox(height: 6),
          TextField(
            controller: _grade,
            style: AppTypography.body,
            decoration: _decoration('예: 고2, 재수생'),
          ),
          const SizedBox(height: 12),
          // 역할·이메일은 편집 대상이 아님(안내만).
          if (widget.profile.email != null)
            Text('이메일 ${widget.profile.email} · 역할·이메일은 여기서 바꿀 수 없어요.',
                style: AppTypography.caption),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _busy ? '저장 중…' : '저장',
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: ColorTokens.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
