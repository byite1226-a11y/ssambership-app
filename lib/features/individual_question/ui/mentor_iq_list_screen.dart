import 'package:flutter/material.dart';

import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/empty_state.dart';
import '../data/individual_question_repository.dart';
import '../data/models/individual_question_models.dart';
import 'iq_detail_screen.dart';
import 'widgets/iq_widgets.dart';

/// 멘토 화면에 함께 담는 데이터(대기 공개 질문 + 내 질문).
class MentorIqListData {
  const MentorIqListData({required this.open, required this.mine});

  final List<OpenIndividualQuestion> open;
  final List<IndividualQuestion> mine;
}

/// 멘토 — 개별질문 목록.
/// '수락 대기'(공개형, 위생 필드만)와 '내 질문'(지정형 + 내가 수락한 것)을 담는다.
class MentorIqListScreen extends StatefulWidget {
  const MentorIqListScreen({super.key, this.loaderOverride, this.onClaim});

  /// 테스트용 데이터 주입. null 이면 실제 레포 사용.
  final Future<MentorIqListData> Function()? loaderOverride;

  /// 테스트용 수락 동작 주입. null 이면 실제 RPC.
  final Future<IqEscrowResult> Function(String questionId)? onClaim;

  @override
  State<MentorIqListScreen> createState() => _MentorIqListScreenState();
}

class _MentorIqListScreenState extends State<MentorIqListScreen> {
  final IndividualQuestionRepository _repo =
      const IndividualQuestionRepository();
  late Future<MentorIqListData> _future;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MentorIqListData> _load() async {
    if (widget.loaderOverride != null) return widget.loaderOverride!();
    final List<OpenIndividualQuestion> open = await _repo.listOpenForMentor();
    final List<IndividualQuestion> mine = await _repo.listForMentor();
    return MentorIqListData(open: open, mine: mine);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _claim(OpenIndividualQuestion q) async {
    if (_claiming) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('질문을 수락할까요?'),
        content: Text(
          '수락하면 답변 담당 멘토가 돼요.\n'
          '${q.title.isEmpty ? '(제목 없음)' : q.title} · ${formatIqCash(q.priceCents)}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('수락'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _claiming = true);
    try {
      await (widget.onClaim ?? _repo.claimAsMentor)(q.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('질문을 수락했어요. 답변을 작성해 주세요.')),
      );
      _refresh();
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => IqDetailScreen(questionId: q.id),
        ),
      );
      if (mounted) _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(iqFailureMessage(e))));
      _refresh(); // 선착 실패 등 — 목록 최신화.
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _openDetail(IndividualQuestion q) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => IqDetailScreen(questionId: q.id),
      ),
    );
    if (changed == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개별질문')),
      body: FutureBuilder<MentorIqListData>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<MentorIqListData> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('개별질문을 불러오지 못했어요.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ColorTokens.danger)),
              ),
            );
          }
          final MentorIqListData data = snap.data ??
              const MentorIqListData(
                open: <OpenIndividualQuestion>[],
                mine: <IndividualQuestion>[],
              );
          if (data.open.isEmpty && data.mine.isEmpty) {
            return const EmptyState(
              icon: Icons.help_outline,
              title: '아직 개별질문이 없어요',
              message: '학생이 지정하거나 공개로 올린 질문이 여기에 보여요.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                if (data.open.isNotEmpty) ...<Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('수락 대기 (공개형)', style: AppTypography.caption),
                  ),
                  for (final OpenIndividualQuestion q in data.open)
                    IqOpenQuestionCard(
                      question: q,
                      onClaim: _claiming ? null : () => _claim(q),
                    ),
                  const SizedBox(height: 12),
                ],
                if (data.mine.isNotEmpty) ...<Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('내 질문', style: AppTypography.caption),
                  ),
                  for (final IndividualQuestion q in data.mine)
                    IqQuestionCard(
                      question: q,
                      onTap: () => _openDetail(q),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
