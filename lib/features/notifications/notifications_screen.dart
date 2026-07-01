import 'package:flutter/material.dart';

import '../../app/app_tabs.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/tokens/typography.dart';
import '../../design/widgets/chip_scroll.dart';
import '../../design/widgets/empty_state.dart';
import 'data/app_notification.dart';
import 'data/notifications_repository.dart';
import 'ui/widgets/notification_card.dart';

/// 알림 센터(5번째 탭). 받은 알림 조회·읽음 + 탭하면 관련 화면으로 이동(딥링크).
/// HomeShell 이 AppBar/하단탭을 제공하므로 본문만 구성한다(자체 Scaffold 없음).
///
/// ★ 조회·읽음 중심. 알림 '생성'은 서버/푸시 몫. 앱 범위(질문방·구독)만 노출 —
///   맞춤의뢰(CR)·환불·개별질문(IQ)은 제외(레포/모델에서 걸러짐).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.repository,
    this.onDeepLinkTab,
  });

  /// 데이터 소스(기본: Supabase). 테스트에서 fake 주입.
  final NotificationsRepository? repository;

  /// 딥링크 탭 이동 훅(기본: TabNavigator.go). 테스트에서 대상 검증용 주입.
  final void Function(int tabIndex)? onDeepLinkTab;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const int _pageSize = 20;

  late final NotificationsRepository _repo;
  final List<AppNotification> _items = <AppNotification>[];
  int _offset = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  bool _unreadOnly = false;
  NotificationKind? _kind; // null = 전체

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? const SupabaseNotificationsRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final NotificationsPage page =
          await _repo.fetch(limit: _pageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          // 앱 범위(질문방·구독)만 — CR·환불·IQ 이중 방어 제외.
          ..addAll(page.items.where((AppNotification n) => n.inAppScope));
        _offset = _pageSize;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final NotificationsPage page =
          await _repo.fetch(limit: _pageSize, offset: _offset);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items.where((AppNotification n) => n.inAppScope));
        _offset += _pageSize;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  int get _unreadCount =>
      _items.where((AppNotification n) => !n.isRead).length;

  List<AppNotification> get _filtered => _items.where((AppNotification n) {
        if (_kind != null && n.kind != _kind) return false;
        if (_unreadOnly && n.isRead) return false;
        return true;
      }).toList();

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    try {
      await _repo.markRead(n.id);
    } catch (e) {
      _showError('읽음 처리에 실패했어요. ($e)');
      return;
    }
    _applyRead(<String>{n.id});
  }

  Future<void> _markAll() async {
    final List<String> ids = _items
        .where((AppNotification n) => !n.isRead)
        .map((AppNotification n) => n.id)
        .toList();
    if (ids.isEmpty) return;
    try {
      await _repo.markAllRead(ids);
    } catch (e) {
      _showError('모두 읽음 처리에 실패했어요. ($e)');
      return;
    }
    _applyRead(ids.toSet());
  }

  void _applyRead(Set<String> ids) {
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        if (ids.contains(_items[i].id)) {
          _items[i] = _items[i].copyWith(isRead: true);
        }
      }
    });
  }

  void _open(AppNotification n) {
    _markRead(n); // 이동 시 읽음 처리(이미 읽음이면 no-op).
    final int tab = n.kind == NotificationKind.subscription
        ? AppTab.myPage
        : AppTab.questionRoom;
    (widget.onDeepLinkTab ?? TabNavigator.go)(tab);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text('안 읽음 $_unreadCount건', style: AppTypography.title),
              ),
              if (_unreadCount > 0)
                TextButton(onPressed: _markAll, child: const Text('모두 읽음')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ChipScroll(
            labels: const <String>['전체', '읽지 않음'],
            selectedIndex: _unreadOnly ? 1 : 0,
            onSelected: (int i) => setState(() => _unreadOnly = i == 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ChipScroll(
            labels: const <String>['전체', '질문방', '구독·결제'],
            selectedIndex:
                _kind == null ? 0 : (_kind == NotificationKind.questionRoom ? 1 : 2),
            onSelected: _onKindSelected,
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  void _onKindSelected(int i) {
    setState(() {
      _kind = i == 0
          ? null
          : (i == 1 ? NotificationKind.questionRoom : NotificationKind.subscription);
    });
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('알림을 불러오지 못했어요.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColorTokens.danger)),
        ),
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: '받은 알림이 없어요',
        message: '새 소식이 오면 여기에 표시돼요.',
      );
    }
    final List<AppNotification> items = _filtered;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: '조건에 맞는 알림이 없어요',
        message: '필터를 바꿔보세요.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int i) {
        if (i >= items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _loadMore,
                      child: const Text('더 보기'),
                    ),
            ),
          );
        }
        final AppNotification n = items[i];
        return NotificationCard(
          notification: n,
          onOpen: () => _open(n),
          onMarkRead: () => _markRead(n),
        );
      },
    );
  }
}
