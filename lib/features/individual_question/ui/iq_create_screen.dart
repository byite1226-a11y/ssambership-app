import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/spacing_tokens.dart';
import '../../../design/tokens/color_tokens.dart';
import '../../../design/tokens/typography.dart';
import '../../../design/widgets/app_card.dart';
import '../../../design/widgets/primary_button.dart';
import '../data/individual_question_repository.dart';
import '../data/models/individual_question_models.dart';

/// 작성 화면 사전 정보(잔액 + 지정형 가격).
class IqCreatePrefill {
  const IqCreatePrefill({required this.balanceCents, this.pricing});

  final int balanceCents;

  /// 지정형일 때 멘토 가격. 미설정이면 null(작성 불가 안내).
  final IqPricing? pricing;
}

/// 새 개별질문 작성 — 캐시 예치(에스크로).
/// [mentorId] 가 있으면 지정형(가격은 멘토 가격표에서 서버가 결정),
/// 없으면 공개형(금액 자유 입력 — 웹과 동일하게 최소/최대 강제 없음).
/// ★ Commerce-Zero 유지: 잔액 부족 시 안내 문구만(충전 링크·유도 없음).
class IqCreateScreen extends StatefulWidget {
  const IqCreateScreen({
    super.key,
    this.mentorId,
    this.mentorName,
    this.prefillOverride,
    this.submitOverride,
  });

  final String? mentorId;
  final String? mentorName;

  /// 테스트용 사전 정보 주입. null 이면 실제 레포 사용.
  final Future<IqCreatePrefill> Function()? prefillOverride;

  /// 테스트용 제출 동작 주입. null 이면 실제 RPC.
  final Future<IndividualQuestion> Function({
    required IndividualQuestionType type,
    required String title,
    required String body,
    int? amountCents,
    String? designatedMentorId,
    String? idempotencyKey,
  })? submitOverride;

  bool get isDirect => mentorId != null;

  @override
  State<IqCreateScreen> createState() => _IqCreateScreenState();
}

class _IqCreateScreenState extends State<IqCreateScreen> {
  final IndividualQuestionRepository _repo =
      const IndividualQuestionRepository();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late Future<IqCreatePrefill> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadPrefill();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<IqCreatePrefill> _loadPrefill() async {
    if (widget.prefillOverride != null) return widget.prefillOverride!();
    final int balance = await _repo.fetchWalletBalanceCents();
    IqPricing? pricing;
    if (widget.isDirect) {
      pricing = await _repo.fetchMentorPricing(widget.mentorId!);
    }
    return IqCreatePrefill(balanceCents: balance, pricing: pricing);
  }

  /// 공개형 입력 금액(캐시) → cents. 유효하지 않으면 null.
  int? get _openAmountCents {
    final int? cash = int.tryParse(_amountController.text.trim());
    if (cash == null || cash <= 0) return null;
    return cash * 100;
  }

  Future<void> _submit(IqCreatePrefill prefill) async {
    if (_submitting) return;
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _snack('제목과 내용을 입력해 주세요.');
      return;
    }

    final int? priceCents =
        widget.isDirect ? prefill.pricing?.amountCents : _openAmountCents;
    if (priceCents == null) {
      _snack(widget.isDirect
          ? '이 멘토는 아직 개별질문 가격을 설정하지 않았어요.'
          : '질문 금액(캐시)을 입력해 주세요.');
      return;
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('질문을 등록할까요?'),
        content: Text(
          '${formatIqCash(priceCents)}가 안전 보관(예치)돼요.\n'
          '답변을 확인하고 해결 완료를 누르면 멘토에게 정산되고,\n'
          '답변 전에는 언제든 취소(환불)할 수 있어요.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('등록'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final Future<IndividualQuestion> Function({
        required IndividualQuestionType type,
        required String title,
        required String body,
        int? amountCents,
        String? designatedMentorId,
        String? idempotencyKey,
      }) submit = widget.submitOverride ?? _repo.createAsStudent;
      await submit(
        type: widget.isDirect
            ? IndividualQuestionType.direct
            : IndividualQuestionType.open,
        title: title,
        body: body,
        // 지정형 가격은 서버가 가격표에서 결정(클라이언트 금액 미신뢰).
        amountCents: widget.isDirect ? null : _openAmountCents,
        designatedMentorId: widget.mentorId,
        idempotencyKey: 'iqapp-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('질문이 전달됐어요. 캐시는 해결 완료 전까지 안전 보관돼요.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack(iqFailureMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDirect ? '개별질문 하기 (지정형)' : '새 개별질문 (공개형)'),
      ),
      body: FutureBuilder<IqCreatePrefill>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<IqCreatePrefill> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('정보를 불러오지 못했어요.\n${snap.error ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ColorTokens.danger)),
              ),
            );
          }
          return _form(snap.data!);
        },
      ),
    );
  }

  Widget _form(IqCreatePrefill prefill) {
    final int? priceCents =
        widget.isDirect ? prefill.pricing?.amountCents : _openAmountCents;
    final bool insufficient =
        priceCents != null && prefill.balanceCents < priceCents;
    final bool directPriceMissing =
        widget.isDirect && prefill.pricing == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 12, AppSpacing.screenH, 24),
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (widget.isDirect) ...<Widget>[
                Text('${widget.mentorName ?? '멘토'}에게 1건 질문해요.',
                    style: AppTypography.body),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('질문 가격', style: AppTypography.caption),
                    Text(
                      prefill.pricing == null
                          ? '가격 미설정'
                          : formatIqCash(prefill.pricing!.amountCents),
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ] else
                const Text(
                  '공개로 올리면 먼저 수락한 멘토가 답변해요.',
                  style: AppTypography.body,
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('내 캐시', style: AppTypography.caption),
                  Text(formatIqCash(prefill.balanceCents),
                      style: AppTypography.body),
                ],
              ),
            ],
          ),
        ),
        if (directPriceMissing) ...<Widget>[
          const SizedBox(height: 10),
          const Text(
            '이 멘토는 아직 개별질문 가격을 설정하지 않아 질문할 수 없어요.',
            style: TextStyle(color: ColorTokens.danger, fontSize: 13),
          ),
        ],
        const SizedBox(height: 14),
        if (!widget.isDirect) ...<Widget>[
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: '질문 금액 (캐시)',
              hintText: '예: $kIqOpenPricePlaceholderCash',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '제목',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          minLines: 5,
          maxLines: 12,
          decoration: const InputDecoration(
            labelText: '질문 내용',
            hintText: '문제 상황과 어디까지 시도했는지 적어 주세요.',
            border: OutlineInputBorder(),
          ),
        ),
        if (insufficient) ...<Widget>[
          const SizedBox(height: 10),
          // ★ 스토어 정책: 결제 유도 링크 없이 '안내'만.
          const Text(
            '캐시가 부족해요. 충전은 웹에서 할 수 있어요.',
            style: TextStyle(color: ColorTokens.danger, fontSize: 13),
          ),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: '질문 등록',
          onPressed:
              _submitting || directPriceMissing ? null : () => _submit(prefill),
        ),
      ],
    );
  }
}

/// 공개형 금액 placeholder(웹 정본 `OPEN_INDIVIDUAL_QUESTION_PRICE_PLACEHOLDER_CASH`
/// 미러 — 예시일 뿐 최소/최대 강제 아님).
const int kIqOpenPricePlaceholderCash = 5000;
