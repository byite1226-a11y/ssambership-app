/// 잉크 입력 모드 — '펜=쓰기, 손가락=이동' 정책의 단일 소스.
///
/// ★ 온디바이스: 입력 판정은 전부 기기 내부(PointerEvent.kind), 외부 SDK 없음.
/// ★ 공유 모듈: 연결노트 필기(S14)와 스캔 주석(S15)이 같은 정책을 쓴다.
///
/// scribble 등 구체 라이브러리 타입에 의존하지 않는다(어댑터에서 매핑).
enum InkInputMode {
  /// 스타일러스(펜)만 그리기. 손가락 터치는 줌/팬으로 통과 — 팜 리젝션의 기본값.
  penOnly,

  /// 펜 + 손가락 모두 그리기. 펜이 없는 사용자를 위한 토글.
  penAndTouch,
}

extension InkInputModeLabel on InkInputMode {
  /// 화면 표시용 한글 라벨(내부 enum명 노출 금지 원칙).
  String get label {
    switch (this) {
      case InkInputMode.penOnly:
        return '펜 전용';
      case InkInputMode.penAndTouch:
        return '손가락 허용';
    }
  }

  /// 저장용 코드값(문서 직렬화에 사용, 화면 노출 금지).
  String get code {
    switch (this) {
      case InkInputMode.penOnly:
        return 'pen_only';
      case InkInputMode.penAndTouch:
        return 'pen_and_touch';
    }
  }

  static InkInputMode fromCode(String? code) {
    switch (code) {
      case 'pen_and_touch':
        return InkInputMode.penAndTouch;
      case 'pen_only':
      default:
        return InkInputMode.penOnly; // 알 수 없는 값은 안전한 기본(펜 전용)으로.
    }
  }
}
