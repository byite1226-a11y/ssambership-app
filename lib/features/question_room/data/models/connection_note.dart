import 'model_parse.dart';

/// 연결노트 작성자 역할. DB connection_notes.author_role text('student'|'mentor').
/// ★ 노트는 컬럼 분리가 아니라 '행 단위 분리' — 한 방에 작성자별 행이 따로 쌓인다.
enum NoteAuthorRole {
  student,
  mentor,

  /// author_role 이 null/미상일 때의 폴백.
  unknown;

  static NoteAuthorRole fromCode(String? code) {
    switch (code?.trim()) {
      case 'student':
        return NoteAuthorRole.student;
      case 'mentor':
        return NoteAuthorRole.mentor;
      default:
        return NoteAuthorRole.unknown;
    }
  }

  String? get code => this == NoteAuthorRole.unknown ? null : name;
}

/// 연결노트(connection_notes) = 방에 대한 작성자별 메모.
class ConnectionNote {
  const ConnectionNote({
    required this.id,
    required this.roomId,
    this.body,
    this.authorId,
    required this.authorRole,
    required this.createdAt,
    required this.updatedAt,
    this.inkPath,
    this.inkThumbPath,
  });

  final String id;

  /// mentor_student_room_id (FK → mentor_student_rooms.id).
  final String roomId;
  final String? body;
  final String? authorId;
  final NoteAuthorRole authorRole;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 필기 원본(ink.json) Storage 경로. 없으면 필기가 아직 없는 노트(텍스트만).
  final String? inkPath;

  /// 필기 썸네일(thumb.png) Storage 경로. 목록 카드 미리보기용(S14-2).
  final String? inkThumbPath;

  /// 필기가 저장돼 있는지(썸네일 경로 유무). 카드에 미리보기를 띄울지 판단.
  bool get hasInk => inkThumbPath != null && inkThumbPath!.isNotEmpty;

  factory ConnectionNote.fromMap(Map<String, dynamic> map) {
    return ConnectionNote(
      id: map['id'] as String,
      roomId: map['mentor_student_room_id'] as String,
      body: map['body'] as String?,
      authorId: map['author_id'] as String?,
      authorRole: NoteAuthorRole.fromCode(map['author_role'] as String?),
      createdAt: parseTime(map['created_at']),
      updatedAt: parseTime(map['updated_at']),
      inkPath: map['ink_path'] as String?,
      inkThumbPath: map['ink_thumb_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'mentor_student_room_id': roomId,
        'body': body,
        'author_id': authorId,
        'author_role': authorRole.code,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'ink_path': inkPath,
        'ink_thumb_path': inkThumbPath,
      };
}
