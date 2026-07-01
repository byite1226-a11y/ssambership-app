import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../shared/errors/app_error.dart';
import 'community_models.dart';

/// 커뮤니티 쓰기(반응·댓글·신고만). ★ 글·숏폼 '작성'은 앱에서 하지 않는다(웹).
/// 본인(author_id/user_id/reporter_id = 현재 사용자) 행만 다룬다(RLS도 강제).
class CommunityWriteRepository {
  const CommunityWriteRepository();

  /// 반응 종류(자유 텍스트 컬럼 — 앱 내부 규약).
  static const String reactionLike = 'like';
  static const String reactionScrap = 'scrap';

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) {
      throw const AppError('백엔드에 연결되어 있지 않아요.');
    }
    return c;
  }

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) throw const AppError('로그인이 필요해요.');
    return id;
  }

  /// 게시판 글 반응 토글(좋아요/스크랩). on=true면 추가, false면 제거.
  /// like_count 자체는 서버(트리거)가 관리 — 앱은 내 반응 행만 만든다/지운다.
  Future<void> toggleBoardReaction({
    required String postId,
    required String type,
    required bool on,
  }) async {
    final String uid = _uid;
    if (on) {
      await _client.from('post_reactions').insert(<String, dynamic>{
        'user_id': uid,
        'post_id': postId,
        'type': type,
      });
    } else {
      await _client
          .from('post_reactions')
          .delete()
          .eq('user_id', uid)
          .eq('post_id', postId)
          .eq('type', type);
    }
  }

  /// 숏폼 반응 토글(좋아요/스크랩).
  Future<void> toggleShortformReaction({
    required String shortformId,
    required String type,
    required bool on,
  }) async {
    final String uid = _uid;
    if (on) {
      await _client.from('shortform_reactions').insert(<String, dynamic>{
        'user_id': uid,
        'shortform_id': shortformId,
        'type': type,
      });
    } else {
      await _client
          .from('shortform_reactions')
          .delete()
          .eq('user_id', uid)
          .eq('shortform_id', shortformId)
          .eq('type', type);
    }
  }

  /// 댓글 작성(본인). status='visible'. author_id 는 항상 현재 사용자.
  Future<CommunityComment> addComment({
    required CommunityPostType postType,
    required String postId,
    required String body,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('community_comments')
        .insert(<String, dynamic>{
          'post_type': postType.code,
          'post_id': postId,
          'author_id': _uid,
          'body': body,
          'status': 'visible',
        })
        .select()
        .single();
    return CommunityComment.fromMap(row);
  }

  /// 신고 접수(content_reports). 외부 연락처 유도 등도 사유로 신고할 수 있다.
  /// reporter_id 는 현재 사용자, status='pending'.
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    await _client.from('content_reports').insert(<String, dynamic>{
      'reporter_id': _uid,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'status': 'pending',
    });
  }
}
