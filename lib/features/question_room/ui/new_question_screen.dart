import 'package:flutter/material.dart';

import '../../../data/mappings/subject_labels.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/primary_button.dart';
import '../data/models/question_thread.dart';
import '../data/models/room.dart';
import '../data/question_room_read_repository.dart';
import '../data/question_room_write_repository.dart';

/// 새 질문 작성. 제목·내용·과목(선택) → 스레드 생성 + 첫 메시지 append.
/// 활성 구독·잔여>0 확인은 호출부(질문영역)에서 게이팅하지만, 실패 에러는 그대로 노출한다.
class NewQuestionScreen extends StatefulWidget {
  const NewQuestionScreen({super.key, required this.room});

  final Room room;

  @override
  State<NewQuestionScreen> createState() => _NewQuestionScreenState();
}

class _NewQuestionScreenState extends State<NewQuestionScreen> {
  final QuestionRoomWriteRepository _write =
      const QuestionRoomWriteRepository();
  final QuestionRoomReadRepository _read = const QuestionRoomReadRepository();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  String? _subjectCode; // null = 선택 안 함

  /// 방 멘토의 담당 과목 코드. null = 로딩 전(드롭다운 잠금), 로드 후 후보 제한 근거.
  List<String>? _mentorCodes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadMentorSubjects();
  }

  /// 방 멘토(teaching_subjects)를 읽어 과목 후보를 제한한다(A1). 실패/빈값이면 전체 폴백.
  Future<void> _loadMentorSubjects() async {
    final List<String> codes =
        await _read.mentorTeachingSubjects(widget.room.mentorId);
    if (!mounted) return;
    setState(() => _mentorCodes = codes);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String title = _title.text.trim();
    final String body = _body.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final QuestionThread thread = await _write.createThread(
        roomId: widget.room.id,
        title: title.isEmpty ? null : title,
        subject: _subjectCode,
      );
      await _write.appendMessage(threadId: thread.id, body: body);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('질문 등록에 실패했어요. ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 질문')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('제목 (선택)', style: AppTypography.caption),
          const SizedBox(height: 6),
          TextField(
            controller: _title,
            style: AppTypography.body,
            decoration: _decoration('한 줄 제목'),
          ),
          const SizedBox(height: 16),
          Text('과목 (선택)', style: AppTypography.caption),
          const SizedBox(height: 6),
          _subjectPicker(),
          const SizedBox(height: 16),
          Text('질문 내용', style: AppTypography.caption),
          const SizedBox(height: 6),
          TextField(
            controller: _body,
            style: AppTypography.body,
            minLines: 5,
            maxLines: 10,
            decoration: _decoration('궁금한 점을 적어주세요.'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _busy ? '등록 중…' : '질문 등록',
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _subjectPicker() {
    // 로딩 전(_mentorCodes==null)에는 잠가 두어, 로드 후 후보에서 빠질 값이
    // 미리 선택되는 문제를 막는다. 로드되면 멘토 담당 과목으로 제한(없으면 전체 폴백).
    final bool loaded = _mentorCodes != null;
    final List<String> codes = loaded
        ? restrictQuestionSubjectCodes(_mentorCodes!)
        : const <String>[];
    final List<DropdownMenuItem<String?>> items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('선택 안 함')),
      for (final String code in codes)
        DropdownMenuItem<String?>(value: code, child: Text(subjectLabel(code))),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorTokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _subjectCode,
          dropdownColor: ColorTokens.surface,
          style: AppTypography.body,
          hint: Text(loaded ? '선택 안 함' : '과목 불러오는 중…',
              style: AppTypography.body),
          items: items,
          // 로딩 중에는 비활성(onChanged=null) — 로드 후 제한된 후보로만 선택.
          onChanged:
              loaded ? (String? v) => setState(() => _subjectCode = v) : null,
        ),
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
