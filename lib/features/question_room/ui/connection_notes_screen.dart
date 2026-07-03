import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/spacing_tokens.dart';
import '../../../design/typography_tokens.dart';
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
import '../../../core/ink/ink_document.dart';
import '../ink_note/data/ink_note_repository.dart';
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
    this.inkRepository,
    this.currentUserId,
    this.inkEditor,
  });

  final Room room;
  final String mentorName;

  /// 노트 로더 오버라이드(테스트 주입). null 이면 실제 레포 조회.
  final Future<List<ConnectionNote>> Function()? notesLoader;

  /// 저장 오버라이드(테스트 주입). null 이면 실제 upsertMyNote(본인 author 행만).
  final Future<void> Function(String body)? onSaveNote;

  /// 필기 저장 레포 오버라이드(테스트 fake 주입). null 이면 Supabase 기본.
  final InkNoteRepository? inkRepository;

  /// 내 사용자 id 오버라이드(테스트용). null 이면 Supabase 세션에서 얻는다.
  final String? currentUserId;

  /// 필기 편집기 진입 오버라이드(테스트 주입). null 이면 InkNoteScreen 을 push 한다.
  /// 테스트는 RepaintBoundary 렌더(썸네일) 없이 결과만 돌려주기 위해 주입한다.
  final Future<InkNoteResult?> Function(InkDocument? initial)? inkEditor;

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

  /// 필기 저장 계층(주입 없으면 Supabase 기본).
  late final InkNoteRepository _inkRepo =
      widget.inkRepository ?? InkNoteRepository.supabase();

  /// 현재 내 노트(있으면). 필기 재편집·썸네일 표시의 기준.
  ConnectionNote? _myInkNote;

  /// 썸네일 서명 URL 메모(경로가 같으면 재발급하지 않는다).
  String? _thumbUrlPath;
  Future<String?>? _thumbUrlFuture;

  String? get _uid =>
      widget.currentUserId ?? SupabaseInit.clientOrNull?.auth.currentUser?.id;

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

  /// 필기 화면 진입 → 돌아온 결과를 실제 저장(connection-note-ink 업로드 + 행 연동).
  /// 기존 필기가 있으면 원본을 불러와 이어서 편집한다. 실패는 앱을 죽이지 않고 안내.
  Future<void> _editInk() async {
    InkDocument? initial;
    final ConnectionNote? mine = _myInkNote;
    if (mine != null && mine.inkPath != null) {
      try {
        initial = await _inkRepo.loadDocument(mine);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('필기를 불러오지 못했어요. ($e)')),
        );
        return;
      }
    }
    if (!mounted) return;

    final InkNoteResult? result = await _launchEditor(initial);
    if (result == null || !mounted) return;

    try {
      await _inkRepo.save(roomId: widget.room.id, result: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필기를 저장했어요.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('필기 저장에 실패했어요. ($e)')),
      );
    }
  }

  /// 필기 편집기 진입(기본: InkNoteScreen push). 테스트는 주입으로 대체한다.
  Future<InkNoteResult?> _launchEditor(InkDocument? initial) {
    if (widget.inkEditor != null) return widget.inkEditor!(initial);
    return Navigator.of(context).push<InkNoteResult>(
      MaterialPageRoute<InkNoteResult>(
        builder: (BuildContext context) =>
            InkNoteScreen(title: '연결노트 필기', initial: initial),
      ),
    );
  }

  /// 썸네일 서명 URL(경로 단위 메모 — 리빌드마다 재발급하지 않게).
  Future<String?> _thumbUrl(ConnectionNote note) {
    final String? path = note.inkThumbPath;
    if (path == null) return Future<String?>.value(null);
    if (_thumbUrlPath != path) {
      _thumbUrlPath = path;
      _thumbUrlFuture = _inkRepo.thumbnailUrl(note);
    }
    return _thumbUrlFuture!;
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

          // 내 노트(필기 재편집·썸네일 기준)를 매 빌드 갱신.
          _myInkNote = mine.isNotEmpty ? mine.first : null;

          // 내 기존 노트 본문으로 에디터 1회 시드.
          if (!_seeded) {
            _editor.text = mine.isNotEmpty ? (mine.first.body ?? '') : '';
            _seeded = true;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH, vertical: AppSpacing.s16),
            children: <Widget>[
              Text('상대 노트', style: AppType.caption),
              const SizedBox(height: AppSpacing.titleBody),
              if (others.isEmpty)
                Text('상대가 남긴 노트가 아직 없어요.', style: AppType.caption)
              else
                for (final ConnectionNote n in others) ...<Widget>[
                  _NoteCard(note: n),
                  const SizedBox(height: AppSpacing.cardGap),
                ],
              const SizedBox(height: AppSpacing.section),
              Text('내 노트', style: AppType.caption),
              const SizedBox(height: AppSpacing.titleBody),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_myInkNote?.hasInk == true) ...<Widget>[
                      _InkThumbnail(
                        note: _myInkNote!,
                        urlLoader: _thumbUrl,
                        onTap: _editInk,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _editor,
                      style: AppType.body,
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
                          label:
                              _myInkNote?.hasInk == true ? '필기 이어 그리기' : '필기로 작성',
                          onPressed: _editInk,
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
                  style: AppType.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.body?.trim().isNotEmpty == true ? note.body!.trim() : '(내용 없음)',
            style: AppType.body,
          ),
        ],
      ),
    );
  }
}

/// 내 노트 필기 미리보기. 눌러서 재편집(이어 그리기) 진입.
/// 배경 흰색 고정(필기 콘텐츠 영역). URL 발급 전/실패 시 아이콘 폴백.
class _InkThumbnail extends StatelessWidget {
  const _InkThumbnail({
    required this.note,
    required this.urlLoader,
    required this.onTap,
  });

  final ConnectionNote note;
  final Future<String?> Function(ConnectionNote) urlLoader;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '내 필기 미리보기 — 눌러서 이어 그리기',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white, // 필기 콘텐츠 영역이라 흰색 고정.
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorTokens.border),
          ),
          child: FutureBuilder<String?>(
            future: urlLoader(note),
            builder: (BuildContext context, AsyncSnapshot<String?> snap) {
              final String? url = snap.data;
              if (url == null) return const _ThumbFallback();
              return Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
                    const _ThumbFallback(),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 썸네일 폴백(로딩 전·실패 시).
class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.draw_rounded, color: ColorTokens.muted, size: 28),
    );
  }
}
