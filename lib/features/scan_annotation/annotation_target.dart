import 'dart:typed_data';

import '../../core/ink/ink_document.dart';
import 'data/scan_annotation_repository.dart';

/// 주석 완료 결과(원본 스트로크 문서 + 평탄화 PNG) 묶음.
class AnnotationResult {
  const AnnotationResult({
    required this.document,
    required this.flattenedPng,
  });

  /// 정규화(0..1) 좌표 스트로크 문서 — 재편집(이어 그리기)용.
  final InkDocument document;

  /// 배경 원본 해상도 평탄화 PNG — 수신 측이 일반 이미지로 보는 결과물.
  final Uint8List flattenedPng;
}

/// [ScanAnnotationScreen] '완료'의 전송 대상 포트(S18, 기획안 §7-2).
///
/// ★ 화면은 '어디로 보내는지'를 모른다 — 정규화 문서와 평탄화 PNG 를 만들어
///   이 포트에 넘길 뿐이다. 질문방 스레드 첨부(기존 S15)·개별질문 첨부(S18)·
///   전송 전 로컬 캡처(학생 작성 화면)가 각각의 구현으로 갈라진다.
abstract class AnnotationTarget {
  Future<void> submit(AnnotationResult result);
}

/// 기본 구현 — 질문방 스레드 첨부(S15 현행 동작 그대로).
///
/// [ScanAnnotationScreen] 에 target 을 주지 않으면 이 구현이 쓰여
/// 기존 질문방 호출부는 아무 변화가 없다.
class QuestionRoomAnnotationTarget implements AnnotationTarget {
  const QuestionRoomAnnotationTarget({
    required this.repository,
    required this.roomId,
    required this.threadId,
  });

  final ScanAnnotationRepository repository;
  final String roomId;
  final String threadId;

  @override
  Future<void> submit(AnnotationResult result) async {
    await repository.submit(
      roomId: roomId,
      threadId: threadId,
      document: result.document,
      flattenedPng: result.flattenedPng,
    );
  }
}

/// 로컬 캡처 구현 — 전송하지 않고 결과만 보관한다.
///
/// 학생 작성 화면(전송 전 첨삭)용: 화면이 pop(true) 된 뒤 호출부가
/// [result] 를 읽어 해당 첨부를 평탄화본으로 대체한다(업로드 전 단계).
class LocalAnnotationTarget implements AnnotationTarget {
  AnnotationResult? result;

  @override
  Future<void> submit(AnnotationResult captured) async {
    result = captured;
  }
}
