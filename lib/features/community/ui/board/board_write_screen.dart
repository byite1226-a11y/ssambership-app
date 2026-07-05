import 'package:flutter/material.dart';

import '../../../../design/shape_tokens.dart';
import '../../../../design/spacing_tokens.dart';
import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';
import '../../../../design/widgets/primary_button.dart';
import '../../data/community_labels.dart';
import '../../data/community_write_repository.dart';

/// 게시판 글쓰기 — 제목 + 본문 + 카테고리만(이미지 없음, 즉시 공개).
/// 성공 시 pop(true) 로 알린다(호출부가 목록 새로고침).
class BoardWriteScreen extends StatefulWidget {
  const BoardWriteScreen({
    super.key,
    this.write = const CommunityWriteRepository(),
  });

  final CommunityWriteRepository write;

  @override
  State<BoardWriteScreen> createState() => _BoardWriteScreenState();
}

class _BoardWriteScreenState extends State<BoardWriteScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  String _category = communityCategoryOptions.first.key;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final String title = _title.text.trim();
    final String body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _snack('제목과 내용을 입력해 주세요.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.write.createPost(
        title: title,
        body: body,
        category: _category,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack('글 등록에 실패했어요. ($e)');
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppType.caption,
      filled: true,
      fillColor: ColorTokens.elevated,
      border: const OutlineInputBorder(
        borderRadius: AppShape.inputRadius,
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 글쓰기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 16, AppSpacing.screenH, 24),
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: _decoration('카테고리'),
            style: AppType.body,
            items: <DropdownMenuItem<String>>[
              for (final MapEntry<String, String> e in communityCategoryOptions)
                DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
            ],
            onChanged: _submitting
                ? null
                : (String? v) {
                    if (v != null) setState(() => _category = v);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            style: AppType.body,
            decoration: _decoration('제목'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            style: AppType.body,
            minLines: 8,
            maxLines: 16,
            decoration:
                _decoration('내용', hint: '커뮤니티 가이드에 맞게 작성해 주세요.'),
          ),
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: _submitting ? '등록 중…' : '등록',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
