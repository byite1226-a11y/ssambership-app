// TODO(S10): router에 mentors 라우트 등록 필요 — S5 완료 후 합침
// (참고: 멘토 찾기 '탭'은 HomeShell 에 이미 연결돼 있고, 상세는 Navigator.push 로 띄우므로
//  현재 router.dart 변경 없이 동작한다. 별도 named-route 가 필요해지면 S5 머지 후 등록할 것.)
import 'package:flutter/material.dart';

import '../../design/shape_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/typography_tokens.dart';
import '../../design/widgets/chip_scroll.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/secondary_button.dart';
import 'data/mentor_directory_repository.dart';
import 'data/mentor_models.dart';
import 'ui/mentor_detail_screen.dart';
import 'ui/widgets/mentor_card.dart';

/// 멘토 찾기 탭(공개·열람 전용). HomeShell 이 AppBar/하단탭을 제공하므로
/// 이 화면은 본문만 구성한다(자체 Scaffold 없음).
///
/// ★ Commerce-Zero: 가격은 '표시'만, 결제·구매 UI 없음. '구독하기'는 웹 브릿지.
class MentorsScreen extends StatefulWidget {
  const MentorsScreen({super.key});

  @override
  State<MentorsScreen> createState() => _MentorsScreenState();
}

enum _Sort { latest, name }

class _MentorsScreenState extends State<MentorsScreen> {
  final MentorDirectoryRepository _repo = const MentorDirectoryRepository();

  static const int _pageSize = 20;
  int _limit = _pageSize;
  late Future<List<MentorListItem>> _future;

  String _query = '';
  String? _subject; // null = 전체
  _Sort _sort = _Sort.latest;

  @override
  void initState() {
    super.initState();
    _future = _repo.list(limit: _limit);
  }

  void _reload() => setState(() => _future = _repo.list(limit: _limit));

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
      _future = _repo.list(limit: _limit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, 12, AppSpacing.screenH, 8),
          child: TextField(
            style: AppType.body,
            onChanged: (String v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: '과목·이름·학교 검색',
              prefixIcon: const Icon(Icons.search_rounded, color: ColorTokens.muted),
              filled: true,
              fillColor: ColorTokens.elevated,
              border: OutlineInputBorder(
                borderRadius: AppShape.inputRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    return FutureBuilder<List<MentorListItem>>(
      future: _future,
      builder:
          (BuildContext context, AsyncSnapshot<List<MentorListItem>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorView(message: '멘토 목록을 불러오지 못했어요.\n${snap.error}');
        }
        final List<MentorListItem> all = snap.data ?? <MentorListItem>[];
        if (all.isEmpty) {
          return const EmptyState(
            icon: Icons.school_outlined,
            title: '아직 공개된 멘토가 없어요',
            message: '곧 멘토들이 등록될 거예요.',
          );
        }

        final List<String> subjects = _distinctSubjects(all);
        final List<MentorListItem> items = _apply(all);

        return Column(
          children: <Widget>[
            if (subjects.isNotEmpty)
              Padding(
                // 좌우 여백은 ChipScroll 내부(스크롤 영역)로 넘겨 끝 칩이 잘리지 않게 한다.
                padding: const EdgeInsets.only(bottom: 6),
                child: ChipScroll(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                  labels: <String>['전체', ...subjects],
                  // _subject 가 목록에 없으면 indexOf=-1 → +1=0 → '전체' 선택.
                  selectedIndex:
                      _subject == null ? 0 : subjects.indexOf(_subject!) + 1,
                  onSelected: (int i) => setState(
                    () => _subject = i == 0 ? null : subjects[i - 1],
                  ),
                ),
              ),
            _SortBar(
              sort: _sort,
              count: items.length,
              onChanged: (_Sort s) => setState(() => _sort = s),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: '검색 결과가 없어요',
                      message: '다른 과목·이름·학교로 찾아보세요.',
                    )
                  : Center(
                      // 태블릿 과폭 방지: 리스트 폭 600 제한·중앙정렬(모바일 390<600 영향 없음, 2열 아님).
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH, 4, AppSpacing.screenH, 16),
                      itemCount: items.length + (_canLoadMore(all) ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.cardGap),
                      itemBuilder: (BuildContext context, int i) {
                        if (i >= items.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SecondaryButton(
                              label: '더 많은 멘토 보기',
                              onPressed: _loadMore,
                            ),
                          );
                        }
                        return MentorCard(
                          item: items[i],
                          onOpen: () => _open(items[i]),
                        );
                      },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// 더보기 노출 조건: 마지막으로 요청한 개수만큼 꽉 찼고(=더 있을 수 있음),
  /// 필터/검색이 걸려 있지 않을 때만(필터 중엔 클라이언트 결과라 의미 없음).
  bool _canLoadMore(List<MentorListItem> all) =>
      _query.isEmpty && _subject == null && all.length >= _limit;

  List<String> _distinctSubjects(List<MentorListItem> all) {
    final Set<String> set = <String>{};
    for (final MentorListItem m in all) {
      set.addAll(m.subjects);
    }
    final List<String> list = set.toList()..sort();
    return list;
  }

  List<MentorListItem> _apply(List<MentorListItem> all) {
    Iterable<MentorListItem> it = all;
    if (_subject != null) {
      it = it.where((MentorListItem m) => m.subjects.contains(_subject));
    }
    if (_query.isNotEmpty) {
      it = it.where((MentorListItem m) => m.searchHaystack.contains(_query));
    }
    final List<MentorListItem> list = it.toList();
    switch (_sort) {
      case _Sort.latest:
        list.sort((MentorListItem a, MentorListItem b) {
          final DateTime ad =
              a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bd =
              b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad); // 최신순
        });
      case _Sort.name:
        list.sort((MentorListItem a, MentorListItem b) =>
            a.displayName.compareTo(b.displayName));
    }
    return list;
  }

  Future<void> _open(MentorListItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MentorDetailScreen(item: item),
      ),
    );
    if (mounted) _reload(); // 돌아오면 최신화(구독 상태 변동 등 반영).
  }
}

/// 정렬 선택 바(데이터로 뒷받침되는 항목만 제공). 인기/추천순은 공개 지표가
/// 없어 제외한다(가짜 순위 금지).
class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.sort,
    required this.count,
    required this.onChanged,
  });

  final _Sort sort;
  final int count;
  final ValueChanged<_Sort> onChanged;

  String get _label => sort == _Sort.latest ? '최신순' : '이름순';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('멘토 $count명', style: AppType.caption),
          PopupMenuButton<_Sort>(
            initialValue: sort,
            onSelected: onChanged,
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<_Sort>>[
              PopupMenuItem<_Sort>(value: _Sort.latest, child: Text('최신순')),
              PopupMenuItem<_Sort>(value: _Sort.name, child: Text('이름순')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_label, style: AppType.caption),
                const Icon(Icons.arrow_drop_down, color: ColorTokens.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ColorTokens.danger),
        ),
      ),
    );
  }
}
