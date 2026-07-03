import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../typography_tokens.dart';

/// 우측에서 슬라이드되는 패널(연결노트·학생정보용).
/// 모바일에서는 화면 폭의 대부분을 덮는다. 호출부는 SlideOverPanel.show(...) 사용.
class SlideOverPanel {
  SlideOverPanel._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    double widthFactor = 0.88,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (BuildContext ctx, Animation<double> a1, Animation<double> a2) {
        return Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            heightFactor: 1,
            child: _PanelBody(title: title, child: child),
          ),
        );
      },
      transitionBuilder: (BuildContext ctx, Animation<double> anim,
          Animation<double> sec, Widget c) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: c,
        );
      },
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorTokens.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(title, style: AppType.title)),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: ColorTokens.secondary),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ColorTokens.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
