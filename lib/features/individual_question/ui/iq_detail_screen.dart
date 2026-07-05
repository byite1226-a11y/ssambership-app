import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../design/spacing_tokens.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/app_badge.dart';
import '../../../design/widgets/app_card.dart';
import '../../../design/widgets/primary_button.dart';
import '../../../design/widgets/secondary_button.dart';
import '../../../shared/format/formatters.dart';
import '../../question_room/data/mentor_lookup_repository.dart';
import '../data/individual_question_repository.dart';
import '../data/models/individual_question_models.dart';
import 'widgets/iq_widgets.dart';

/// 상세 화면 데이터 묶음(질문 + 메시지 + 첨부 + 멘토 표시명).
class IqDetailData {
  const IqDetailData({
    required this.question,
    required this.messages,
    required this.attachments,
    this.mentorName,
  });

  final IndividualQuestion question;
  final List<IqMessage> messages;
  final List<IqAttachment> attachments;

  /// 학생 화면용 멘토 표시명(공개 RPC). 없으면 '멘토'.
  final String? mentorName;
}

/// 개별질문 상세 — 학생·멘토 공용. 역할·상태에 따라 액션이 달라진다.
/// - 학생: 답변 도착 → [해결 완료(정산)] / 답변 전 → [질문 취소(환불)]
/// - 멘토: 답변중(수락·지정) → 답변 작성
/// 변경이 있었으면 pop(true) 로 알린다(호출부 새로고침).
class IqDetailScreen extends StatefulWidget {
  const IqDetailScreen({
    super.key,
    required this.questionId,
    this.loaderOverride,
    this.roleOverride,
  });

  final String questionId;

  /// 테스트용 데이터 주입. null 이면 실제 레포 사용.
  final Future<IqDetailData> Function()? loaderOverride;

  /// 테스트용 역할 주입. null 이면 AuthService 의 현재 역할.
  final AppRole? roleOverride;

  @override
  State<IqDetailScreen> createState() => _IqDetailScreenState();
}

class _IqDetailScreenState extends State<IqDetailScreen> {
  final IndividualQuestionRepository _repo =
      const IndividualQuestionRepository();
  final MentorLookupRepository _mentorLookup = const MentorLookupRepository();
  final TextEditingController _answerController = TextEditingController();

  late Future<IqDetailData> _future;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<IqDetailData> _load() async {
    if (widget.loaderOverride != null) return widget.loaderOverride!();
    final IndividualQuestion? q = await _repo.fetch(widget.questionId);
    if (q == null) {
      throw Exception('질문을 찾을 수 없어요.');
    }
    final List<IqMessage> messages = await _repo.listMessages(q.id);
    final List<IqAttachment> attachments = await _repo.listAttachments(q.id);
    String? mentorName;
    final String? mentorId = q.mentorId;
    if (mentorId != null && _role == AppRole.student) {
      try {
        mentorName = (await _mentorLookup.fetch(mentorId))?.displayName;
      } catch (_) {
        mentorName = null; // 이름 조회 실패는 치명적이지 않다.
      }
    }
    return IqDetailData(
      question: q,
      messages: messages,
      attachments: attachments,
      mentorName: mentorName,
    );
  }

  void _refresh() => setState(() => _future = _load());

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirm(String title, String content, String okLabel) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(okLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _changed = true;
      _refresh();
    } catch (e) {
      _snack(iqFailureMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _release() async {
    final bool ok = await _confirm(
      '해결 완료할까요?',
      '확정하면 안전 보관 중이던 캐시가 멘토에게 정산돼요.\n이후에는 되돌릴 수 없어요.',
      '해결 완료',
    );
    if (!ok) return;
    await _runAction(() async {
      await _repo.release(widget.questionId);
      _snack('해결 완료했어요. 안전 보관 중이던 캐시가 멘토에게 정산됐어요.');
    });
  }

  Future<void> _refund() async {
    final bool ok = await _confirm(
      '질문을 취소할까요?',
      '취소하면 안전 보관 중인 캐시가 지갑으로 돌아와요.',
      '질문 취소',
    );
    if (!ok) return;
    await _runAction(() async {
      await _repo.refund(widget.questionId);
      _snack('질문을 취소했어요. 캐시가 지갑으로 돌아왔어요.');
    });
  }

  Future<void> _submitAnswer() async {
    final String body = _answerController.text.trim();
    if (body.isEmpty) {
      _snack('답변 내용을 입력해 주세요.');
      return;
    }
    final bool ok = await _confirm(
      '답변을 등록할까요?',
      '등록하면 학생에게 답변 도착으로 표시돼요.\n학생이 해결 완료를 누르면 정산 예정 금액으로 잡혀요.',
      '답변 등록',
    );
    if (!ok) return;
    await _runAction(() async {
      await _repo.answer(widget.questionId, body);
      _answerController.clear();
      _snack('답변을 등록했어요.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('개별질문')),
        body: FutureBuilder<IqDetailData>(
          future: _future,
          builder:
              (BuildContext context, AsyncSnapshot<IqDetailData> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || snap.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('질문을 불러오지 못했어요.\n${snap.error ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ColorTokens.danger)),
                ),
              );
            }
            return _body(snap.data!);
          },
        ),
      ),
    );
  }

  AppRole get _role => widget.roleOverride ?? AuthService.instance.currentRole;

  Widget _body(IqDetailData data) {
    final IndividualQuestion q = data.question;
    final bool isStudent = _role == AppRole.student;
    final bool isMentor = _role == AppRole.mentor;
    final String? remaining = formatIqExpiryRemaining(q.expiresAt, q.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 12, AppSpacing.screenH, 24),
      children: <Widget>[
        // 헤더: 유형·상태·가격·마감.
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppBadge(label: iqTypeLabel(q.type), tinted: true),
                  const SizedBox(width: 6),
                  IqStatusPill(status: q.status),
                  const Spacer(),
                  Text(formatIqCash(q.priceCents), style: AppTypography.body),
                ],
              ),
              const SizedBox(height: 10),
              Text(q.title.isEmpty ? '(제목 없음)' : q.title,
                  style: AppTypography.title),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  if (isStudent)
                    Text(data.mentorName ?? '멘토',
                        style: AppTypography.caption),
                  if (q.createdAt != null) ...<Widget>[
                    if (isStudent) const SizedBox(width: 8),
                    Text(Formatters.relativeKorean(q.createdAt!),
                        style: AppTypography.caption),
                  ],
                  if (remaining != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(remaining, style: AppTypography.caption),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 질문 본문.
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('질문', style: AppTypography.caption),
              const SizedBox(height: 8),
              Text(q.body, style: AppTypography.body),
            ],
          ),
        ),
        if (data.attachments.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _AttachmentsCard(attachments: data.attachments, repo: _repo),
        ],
        if (data.messages.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('답변', style: AppTypography.caption),
                for (final IqMessage m in data.messages) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(m.body, style: AppTypography.body),
                  if (m.createdAt != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(Formatters.relativeKorean(m.createdAt!),
                        style: AppTypography.caption),
                  ],
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // 상태 안내 + 액션.
        if (isStudent) ..._studentActions(q),
        if (isMentor) ..._mentorActions(q),
      ],
    );
  }

  List<Widget> _studentActions(IndividualQuestion q) {
    final List<Widget> out = <Widget>[];
    if (iqAwaitingAnswer(q.status)) {
      out.add(const Text(
        '질문이 전달됐어요. 안전 보관 중인 캐시는 해결 완료를 누르기 전까지 보관돼요.',
        style: AppTypography.caption,
      ));
      out.add(const SizedBox(height: 10));
    }
    if (iqCanStudentRelease(q.status)) {
      out.add(PrimaryButton(
        label: '해결 완료 (멘토에게 정산)',
        onPressed: _busy ? null : _release,
      ));
      out.add(const SizedBox(height: 8));
    }
    if (iqCanStudentRefund(q.status)) {
      out.add(SecondaryButton(
        label: '질문 취소 (캐시 환불)',
        onPressed: _busy ? null : _refund,
      ));
    }
    if (q.status == IndividualQuestionStatus.released) {
      out.add(const Text(
        '해결 완료했어요. 안전 보관 중이던 캐시가 멘토에게 정산됐어요.',
        style: AppTypography.caption,
      ));
    }
    return out;
  }

  List<Widget> _mentorActions(IndividualQuestion q) {
    if (!iqCanMentorAnswer(q.status)) {
      if (q.status == IndividualQuestionStatus.answered) {
        return const <Widget>[
          Text('답변을 등록했어요. 학생이 해결 완료하면 정산 예정으로 잡혀요.',
              style: AppTypography.caption),
        ];
      }
      if (q.status == IndividualQuestionStatus.released) {
        return const <Widget>[
          Text('정산이 완료된 질문이에요.', style: AppTypography.caption),
        ];
      }
      return const <Widget>[];
    }
    return <Widget>[
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('답변 작성', style: AppTypography.caption),
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '학생이 이해할 수 있게 풀이 과정을 함께 적어 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: '답변 등록',
              onPressed: _busy ? null : _submitAnswer,
            ),
          ],
        ),
      ),
    ];
  }
}

/// 첨부 카드 — 이미지는 서명 URL 로 인라인 표시, 그 외 파일은 이름만(조회 전용).
class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard({required this.attachments, required this.repo});

  final List<IqAttachment> attachments;
  final IndividualQuestionRepository repo;

  bool _isImage(IqAttachment a) =>
      (a.mimeType ?? '').toLowerCase().startsWith('image/');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('첨부', style: AppTypography.caption),
          for (final IqAttachment a in attachments) ...<Widget>[
            const SizedBox(height: 8),
            if (_isImage(a))
              FutureBuilder<String>(
                future: repo.signedAttachmentUrl(a.storagePath),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || snap.data == null) {
                    return const Text('이미지를 불러오지 못했어요.',
                        style: AppTypography.caption);
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      snap.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text(
                        '이미지를 불러오지 못했어요.',
                        style: AppTypography.caption,
                      ),
                    ),
                  );
                },
              )
            else
              Row(
                children: <Widget>[
                  const Icon(Icons.attach_file,
                      size: 18, color: ColorTokens.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.fileName ?? '첨부 파일',
                      style: AppTypography.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text('웹에서 확인', style: AppTypography.caption),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
