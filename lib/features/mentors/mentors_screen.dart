// TODO(S10): router에 mentors 라우트 등록 필요 — S5 완료 후 합침
// (참고: 멘토 찾기 '탭'은 HomeShell 에 이미 연결돼 있고, 상세는 Navigator.push 로 띄우므로
//  현재 router.dart 변경 없이 동작한다. 별도 named-route 가 필요해지면 S5 머지 후 등록할 것.)
import 'package:flutter/material.dart';

import '../../design/role_accent.dart';
import '../../design/shape_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../design/tokens/color_tokens.dart';
import '../../design/typography_tokens.dart';
import '../../design/widgets/chip_scroll.dart';
import '../../design/widgets/empty_state.dart';
import 'data/mentor_directory_repository.dart';
import 'data/mentor_directory_view.dart';
import 'data/mentor_favorites_repository.dart';
import 'data/mentor_models.dart';
import 'data/mentor_sort.dart';
import 'data/mentor_subject.dart';
import 'ui/mentor_detail_screen.dart';
import 'ui/widgets/mentor_card.dart';
import '../../shared/errors/friendly_error.dart';

/// 멘토 찾기 탭(공개·열람 전용). HomeShell 이 AppBar/하단탭을 제공하므로
/// 이 화면은 본문만 구성한다(자체 Scaffold 없음).
///
/// ★ Commerce-Zero: 가격은 표시하지 않고 결제·구매 UI 없음. '구독하기'는 웹 브릿지.
/// ★ 전체 로드: 공개 멘토를 한 번에(검증된 상한 200) 불러와 검색·과목 필터·정렬을
///   전체 집합에 적용한다 — 최신 N명 창에서만 검색되던 문제를 제거한다.
class MentorsScreen extends StatefulWidget {
  const MentorsScreen({super.key});

  @override
  State<MentorsScreen> createState() => _MentorsScreenState();
}

class _MentorsScreenState extends State<MentorsScreen> {
  final MentorDirectoryRepository _repo = const MentorDirectoryRepository();
  final MentorFavoritesRepository _favRepo = const MentorFavoritesRepository();

  late Future<List<MentorListItem>> _future;

  String _query = '';
  String? _subjectKey; // canonical key(= MentorSubject.key). null = 전체
  MentorSort _sort = MentorSort.latest;

  /// 내가 찜한 멘토 id(하트 채움·상단 카운트용). 비로그인/실패면 빈 집합.
  Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _repo.listComplete();
    _loadFavorites();
  }

  // 블록 바디: setState(() => _future = future)는 Future를 반환해 리빌드가 취소된다.
  void _reload() => setState(() {
        _future = _repo.listComplete();
      });

  Future<void> _loadFavorites() async {
    final Set<String> ids = await _favRepo.myFavoriteMentorIds();
    if (mounted) setState(() => _favoriteIds = ids);
  }

  /// 하트 탭 — 비로그인이면 로그인 유도, 아니면 낙관적 토글 후 서버 반영(실패 시 되돌림).
  Future<void> _toggleFavorite(String mentorId) async {
    if (!_favRepo.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인하면 멘토를 찜할 수 있어요.')),
        );
      }
      return;
    }
    final bool wasFav = _favoriteIds.contains(mentorId);
    setState(() => _favoriteIds = _withToggle(_favoriteIds, mentorId, !wasFav));
    final bool ok =
        wasFav ? await _favRepo.remove(mentorId) : await _favRepo.add(mentorId);
    if (!ok && mounted) {
      setState(
          () => _favoriteIds = _withToggle(_favoriteIds, mentorId, wasFav));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('찜 처리에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  /// 불변 집합 토글(add=true면 추가, false면 제거).
  static Set<String> _withToggle(Set<String> src, String id, bool add) {
    final Set<String> next = <String>{...src};
    if (add) {
      next.add(id);
    } else {
      next.remove(id);
    }
    return next;
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
              prefixIcon:
                  const Icon(Icons.search_rounded, color: ColorTokens.muted),
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
        // 상단 '찜한 멘토 N' 카운트(로그인 시). 전용 목록/필터는 두지 않는다(웹 패리티).
        if (_favRepo.isLoggedIn)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, 0, AppSpacing.screenH, 6),
            child: Row(
              children: <Widget>[
                Icon(Icons.favorite_rounded,
                    size: 14, color: AppAccent.of(context).accent),
                const SizedBox(width: 5),
                Text('찜한 멘토 ${_favoriteIds.length}', style: AppType.caption),
              ],
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
          return _ErrorView(
              message: '멘토 목록을 불러오지 못했어요.\n${friendlyError(snap.error!)}');
        }
        final List<MentorListItem> all = snap.data ?? <MentorListItem>[];
        if (all.isEmpty) {
          return const EmptyState(
            icon: Icons.school_outlined,
            title: '아직 공개된 멘토가 없어요',
            message: '곧 멘토들이 등록될 거예요.',
          );
        }

        // 전체 로드 집합 기준 canonical 과목 칩 · 필터/검색/정렬 결과.
        final List<MentorSubject> subjects = distinctSubjects(all);
        final List<MentorListItem> items = filterSearchSortMentors(
          all: all,
          query: _query,
          subjectKey: _subjectKey,
          sort: _sort,
        );

        return Column(
          children: <Widget>[
            if (subjects.isNotEmpty)
              Padding(
                // 좌우 여백은 ChipScroll 내부(스크롤 영역)로 넘겨 끝 칩이 잘리지 않게 한다.
                padding: const EdgeInsets.only(bottom: 6),
                child: ChipScroll(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH),
                  // 칩은 한글 라벨만 노출(raw 코드 노출 금지).
                  labels: <String>[
                    '전체',
                    for (final MentorSubject s in subjects) s.label,
                  ],
                  // 선택 상태는 canonical key 로 유지 — 목록에 없으면 '전체'.
                  selectedIndex: _selectedChipIndex(subjects),
                  onSelected: (int i) => setState(
                    () => _subjectKey = i == 0 ? null : subjects[i - 1].key,
                  ),
                ),
              ),
            _SortBar(
              sort: _sort,
              count: items.length,
              onChanged: (MentorSort s) => setState(() => _sort = s),
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
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.cardGap),
                          itemBuilder: (BuildContext context, int i) {
                            return MentorCard(
                              item: items[i],
                              onOpen: () => _open(items[i]),
                              favorited: _favoriteIds.contains(items[i].id),
                              onToggleFavorite: () =>
                                  _toggleFavorite(items[i].id),
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

  /// 현재 선택된 과목 key 의 칩 인덱스(+1은 '전체' 오프셋). key 가 목록에 없으면 0('전체').
  int _selectedChipIndex(List<MentorSubject> subjects) {
    if (_subjectKey == null) return 0;
    for (int i = 0; i < subjects.length; i++) {
      if (subjects[i].key == _subjectKey) return i + 1;
    }
    return 0;
  }

  Future<void> _open(MentorListItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MentorDetailScreen(
          item: item,
          initialFavorited: _favoriteIds.contains(item.id),
        ),
      ),
    );
    if (mounted) {
      _loadFavorites(); // 상세에서 찜이 바뀌었을 수 있어 동기화.
      _reload(); // 돌아오면 최신화(구독 상태 변동 등 반영).
    }
  }
}

/// 정렬 선택 바(데이터로 뒷받침되는 항목만 제공). 인기/추천순은 공개 지표가
/// 없어 제외한다(가짜 순위 금지). 가격은 앱에서 노출하지 않아 가격순도 없다.
class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.sort,
    required this.count,
    required this.onChanged,
  });

  final MentorSort sort;
  final int count;
  final ValueChanged<MentorSort> onChanged;

  String get _label => mentorSortLabel(sort);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('멘토 $count명', style: AppType.caption),
          PopupMenuButton<MentorSort>(
            initialValue: sort,
            onSelected: onChanged,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MentorSort>>[
              for (final MentorSort s in MentorSort.values)
                PopupMenuItem<MentorSort>(
                    value: s, child: Text(mentorSortLabel(s))),
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
