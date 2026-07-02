import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/app_badge.dart';
import '../../../design/widgets/app_card.dart';
import '../../../design/widgets/primary_button.dart';
import '../../../design/widgets/secondary_button.dart';
import '../../../shared/format/formatters.dart';
import '../../../shared/labels/question_room_labels.dart';
import '../data/models/connection_note.dart';
import '../data/models/room.dart';
import '../data/question_room_read_repository.dart';
import '../data/question_room_write_repository.dart';
import '../ink_note/ink_note_result.dart';
import '../ink_note/ink_note_screen.dart';

/// 연결노트(풀스크린). 멘토/학생 노트를 author_role 로 구분.
/// 본인 노트만 추가/수정한다(쓰기 레포가 본인 author 행만 다룸).
class ConnectionNotesScreen extends StatefulWidget {
  const ConnectionNotesScreen({
    super.key,
    required this.room,
    required this.mentorName,
    this.notesLoader,
    this.onSaveNote,
  });

  final Room room;
  final String mentorName;

  /// 노트 로더 오버라이드(테스트 주입). null 이면 실제 레포 조회.
  final Future<List<ConnectionNote>> Function()? notesLoader;

  /// 저장 오버라이드(테스트 주입). null 이면 실제 upsertMyNote(본인 author 행만).
  final Future<void> Function(String body)? onSaveNote;

  @override
  State<ConnectionNotesScreen> createState() => _ConnectionNotesScreenState();
}

class _ConnectionNotesScreenState extends State<ConnectionNotesScreen> {
  final QuestionRoomReadRepository _read = const QuestionRoomReadRepository();
  final QuestionRoomWriteRepository _write =
      const QuestionRoomWriteRepository();
  final TextEditingController _editor = TextEditingController();

  late Future<List<ConnectionNote>> _future;
  bool _saving = false;
  bool _seeded = false;

  /// 필기 화면이 돌려준 결과를 보관(저장 연결은 S14-2). 재진입 시 이어 그리기용.
  InkNoteResult? _pendingInk;

  String? get _uid => SupabaseInit.clientOrNull?.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _future = _loadNotes();
  }

  Future<List<ConnectionNote>> _loadNotes() =>
      widget.notesLoader != null ? widget.notesLoader!() : _read.notes(widget.room.id);

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _seeded = false;
    setState(() => _future = _loadNotes());
  }

  Future<void> _save() async {
    final String body = _editor.text.trim();
    if (body.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      if (widget.onSaveNote != null) {
        await widget.onSaveNote!(body);
      } else {
        await _write.upsertMyNote(roomId: widget.room.id, body: body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('노트를 저장했어요.')),
        );
        await _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했어요. ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 필기 화면으로 진입. 돌아온 결과는 보관만 하고 저장은 다음 세션(S14-2)에서 연결.
  Future<void> _openInkNote() async {
    final InkNoteResult? result = await Navigator.of(context).push<InkNoteResult>(
      MaterialPageRoute<InkNoteResult>(
        builder: (BuildContext context) => InkNoteScreen(
          title: '연결노트 필기',
          initial: _pendingInk?.document, // 저장 전 임시 필기를 이어서 편집.
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _pendingInk = result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('필기를 저장할 준비가 됐어요. (저장 기능 연결 예정)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('연결노트')),
      body: FutureBuilder<List<ConnectionNote>>(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<List<ConnectionNote>> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('노트를 불러오지 못했어요.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ColorTokens.danger)),
              ),
            );
          }
          final List<ConnectionNote> notes = snap.data ?? <ConnectionNote>[];
          final List<ConnectionNote> mine = notes
              .where((ConnectionNote n) => _uid != null && n.authorId == _uid)
              .toList();
          final List<ConnectionNote> others = notes
              .where((ConnectionNote n) => !(_uid != null && n.authorId == _uid))
              .toList()
            ..sort((ConnectionNote a, ConnectionNote b) =>
                a.createdAt.compareTo(b.createdAt)); // 상대 노트 시간순

          // 내 기존 노트 본문으로 에디터 1회 시드.
          if (!_seeded) {
            _editor.text = mine.isNotEmpty ? (mine.first.body ?? '') : '';
            _seeded = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text('상대 노트', style: AppTypography.caption),
              const SizedBox(height: 10),
              if (others.isEmpty)
                Text('상대가 남긴 노트가 아직 없어요.', style: AppTypography.caption)
              else
                for (final ConnectionNote n in others) ...<Widget>[
                  _NoteCard(note: n),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 18),
              Text('내 노트', style: AppTypography.caption),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _editor,
                      style: AppTypography.body,
                      minLines: 3,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: '이 멘토방에 대한 내 메모를 남겨요.',
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        PrimaryButton(
                          label: _saving ? '저장 중…' : '내 노트 저장',
                          onPressed: _saving ? null : _save,
                          expand: false,
                        ),
                        const SizedBox(width: 8),
                        SecondaryButton(
                          label: '필기로 작성',
                          onPressed: _openInkNote,
                          expand: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final ConnectionNote note;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppBadge(
                label: QuestionRoomLabels.noteAuthorRole(note.authorRole),
                tinted: note.authorRole == NoteAuthorRole.mentor,
              ),
              const Spacer(),
              Text(Formatters.relativeKorean(note.updatedAt),
                  style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.body?.trim().isNotEmpty == true ? note.body!.trim() : '(내용 없음)',
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }
}
