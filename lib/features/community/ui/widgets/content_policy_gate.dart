import 'package:flutter/material.dart';

import '../../../../design/tokens/color_tokens.dart';
import '../../../../design/typography_tokens.dart';

/// 콘텐츠 게시 전 정책 동의 게이트(UGC 규정 준수 — 게시글·댓글 공통).
///
/// ★ 앱스토어 심사(Apple 1.2 / Google UGC): 사용자가 콘텐츠를 만들기 전에
///   '불쾌·불법·음란 콘텐츠 무관용' 정책에 **능동 동의**하도록 요구된다.
///   가입이 웹 전용이라 인앱 EULA 접점이 없으므로, 최초 게시 동선에서 1회 동의를 받는다.
///
/// 저장은 세션 스코프(인메모리) — 앱 실행마다 최초 1회 노출된다. 별도 저장 패키지
/// 의존성을 추가하지 않기 위한 선택이며, 심사 관점(게시 전 동의 노출)에는 충분하다.
class ContentPolicyGate {
  ContentPolicyGate._();

  /// 이번 실행에서 동의했는지(중복 노출 방지). 테스트에서 리셋 가능.
  static bool agreedThisSession = false;

  /// 게시 전 정책 동의를 보장한다. 이미 동의했으면 즉시 true.
  /// 다이얼로그에서 '동의' → true, 취소/바깥 탭 → false.
  static Future<bool> ensureAgreed(BuildContext context) async {
    if (agreedThisSession) return true;
    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) => const _ContentPolicyDialog(),
    );
    if (ok == true) {
      agreedThisSession = true;
      return true;
    }
    return false;
  }
}

class _ContentPolicyDialog extends StatelessWidget {
  const _ContentPolicyDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surface,
      title: Text('커뮤니티 이용 규정', style: AppType.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '쌤버십은 불쾌하거나 불법·음란·폭력적이거나 타인을 비방·괴롭히는 콘텐츠를 '
            '허용하지 않아요. 위반 콘텐츠는 사전 통지 없이 삭제되고 계정이 제한될 수 있어요.',
            style: AppType.body,
          ),
          const SizedBox(height: 12),
          Text(
            '부적절한 게시물은 신고하거나 작성자를 차단할 수 있어요. '
            '게시하면 위 규정에 동의하는 것으로 간주돼요.',
            style: AppType.caption,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('동의하고 계속'),
        ),
      ],
    );
  }
}
