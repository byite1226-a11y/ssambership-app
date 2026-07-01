import 'package:flutter/foundation.dart';

import 'models/question_message.dart';

/// 채팅 메시지 상태 컨트롤러 — 실시간 수신분과 내가 보낸 메시지를 함께 모은다.
///
/// ★ 중복 id 는 무시(같은 메시지가 낙관적 추가 + 실시간으로 두 번 와도 1개만).
///   순서는 created_at 오름차순 유지. append 전용(수정/삭제 없음).
class ThreadMessagesController extends ChangeNotifier {
  ThreadMessagesController([List<QuestionMessage> initial = const <QuestionMessage>[]]) {
    resetTo(initial, notify: false);
  }

  final List<QuestionMessage> _items = <QuestionMessage>[];
  final Set<String> _ids = <String>{};

  List<QuestionMessage> get items => List<QuestionMessage>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  /// 메시지 1개 추가. 이미 있는 id 면 false(중복 무시).
  bool add(QuestionMessage m) {
    if (!_ids.add(m.id)) return false;
    _items.add(m);
    _sort();
    notifyListeners();
    return true;
  }

  /// 전체 교체(폴백 재조회 결과 반영). [notify] false 면 알림 생략(초기화용).
  void resetTo(List<QuestionMessage> list, {bool notify = true}) {
    _items.clear();
    _ids.clear();
    for (final QuestionMessage m in list) {
      if (_ids.add(m.id)) _items.add(m);
    }
    _sort();
    if (notify) notifyListeners();
  }

  void _sort() {
    _items.sort((QuestionMessage a, QuestionMessage b) =>
        a.createdAt.compareTo(b.createdAt));
  }
}
