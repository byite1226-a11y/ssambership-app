import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../shared/errors/app_error.dart';
import 'attachment_upload.dart';

/// 첨부 Storage 접근 백엔드(서명 URL 발급 + 원본 다운로드). 주입형 포트.
///
/// ★ 캐시/만료 로직은 [AttachmentUrlResolver] 가 갖고, Supabase 구체 호출은 이
///   포트 뒤로 숨긴다 → 테스트는 fake 포트 + 가짜 시계로 캐시·만료를 검증한다.
abstract class AttachmentUrlBackend {
  /// storage_path → 서명 URL(만료 [expiresInSeconds]).
  Future<String> createSignedUrl(String storagePath, int expiresInSeconds);

  /// storage_path 원본 바이트(주석 배경 등).
  Future<Uint8List> download(String storagePath);
}

/// 첨부 이미지 표시용 서명 URL 리졸버 — 만료 전 재사용(메모리 캐시).
///
/// 같은 storage_path 는 발급 URL 을 캐시에 담아 만료 전까지 재사용한다(불필요한
/// 재발급·요청 절감). 다운로드는 캐시하지 않고 그대로 위임한다.
class AttachmentUrlResolver {
  AttachmentUrlResolver(
    this._backend, {
    Duration ttl = const Duration(hours: 1),
    DateTime Function()? now,
  })  : _ttl = ttl,
        _now = now ?? DateTime.now;

  /// 운영 기본 구현(Supabase Storage).
  factory AttachmentUrlResolver.supabase() =>
      AttachmentUrlResolver(const SupabaseAttachmentUrlBackend());

  final AttachmentUrlBackend _backend;
  final Duration _ttl;
  final DateTime Function() _now;

  final Map<String, _CachedUrl> _cache = <String, _CachedUrl>{};

  /// 서명 URL(만료 전이면 캐시 재사용). 만료 시각 이후엔 재발급.
  Future<String> signedUrl(String storagePath) async {
    final _CachedUrl? cached = _cache[storagePath];
    if (cached != null && _now().isBefore(cached.expiresAt)) {
      return cached.url;
    }
    final int seconds = _ttl.inSeconds;
    final String url = await _backend.createSignedUrl(storagePath, seconds);
    _cache[storagePath] = _CachedUrl(url, _now().add(_ttl));
    return url;
  }

  /// 원본 바이트 다운로드(주석 배경 진입 등). 캐시하지 않는다.
  Future<Uint8List> download(String storagePath) =>
      _backend.download(storagePath);
}

class _CachedUrl {
  const _CachedUrl(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
}

/// Supabase Storage 백엔드(첨부 버킷).
class SupabaseAttachmentUrlBackend implements AttachmentUrlBackend {
  const SupabaseAttachmentUrlBackend();

  SupabaseClient get _client {
    final SupabaseClient? c = SupabaseInit.clientOrNull;
    if (c == null) throw const AppError('백엔드에 연결되어 있지 않아요.');
    return c;
  }

  @override
  Future<String> createSignedUrl(String storagePath, int expiresInSeconds) =>
      _client.storage
          .from(SupabaseAttachmentUploader.bucket)
          .createSignedUrl(storagePath, expiresInSeconds);

  @override
  Future<Uint8List> download(String storagePath) => _client.storage
      .from(SupabaseAttachmentUploader.bucket)
      .download(storagePath);
}

/// 첨부가 이미지인지(썸네일/뷰어 대상). mime 이 image/* 면 true.
bool isImageAttachment(String? mimeType) =>
    (mimeType ?? '').toLowerCase().startsWith('image/');
