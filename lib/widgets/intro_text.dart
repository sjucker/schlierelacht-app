import 'package:flutter/material.dart';

/// The short explanatory paragraph(s) the website shows at the top of a list
/// page (Programm, Sponsoren, …).
class IntroText extends StatelessWidget {
  const IntroText(this.paragraphs, {super.key, this.padding});

  /// Each entry is one paragraph; a [TextSpan] allows inline emphasis/links.
  final List<InlineSpan> paragraphs;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[if (i > 0) const SizedBox(height: 8), Text.rich(paragraphs[i], style: style)],
        ],
      ),
    );
  }
}
