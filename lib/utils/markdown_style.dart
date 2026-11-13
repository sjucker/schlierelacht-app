import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';

/// The app theme's [MarkdownStyleSheet] — pass it to every `MarkdownBody`.
///
/// `flutter_markdown_plus` still builds its default sheet from the deprecated
/// `package:flutter/material.dart` `Theme`, which the `material_ui` `MaterialApp` no
/// longer provides, so without this the markdown would fall back to Flutter's default
/// theme. Mirrors `MarkdownStyleSheet.fromTheme`, reading `material_ui`'s [ThemeData].
/// Drop it once the package reads `material_ui`'s theme itself.
MarkdownStyleSheet markdownStyleSheet(ThemeData theme) {
  final text = theme.textTheme;
  final body = text.bodyMedium!;
  return MarkdownStyleSheet(
    a: const TextStyle(color: Colors.blue),
    p: body,
    pPadding: EdgeInsets.zero,
    code: body.copyWith(backgroundColor: theme.cardTheme.color, fontFamily: 'monospace', fontSize: body.fontSize! * 0.85),
    h1: text.headlineSmall,
    h1Padding: EdgeInsets.zero,
    h2: text.titleLarge,
    h2Padding: EdgeInsets.zero,
    h3: text.titleMedium,
    h3Padding: EdgeInsets.zero,
    h4: text.bodyLarge,
    h4Padding: EdgeInsets.zero,
    h5: text.bodyLarge,
    h5Padding: EdgeInsets.zero,
    h6: text.bodyLarge,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.italic),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    blockquote: body,
    img: body,
    checkbox: body.copyWith(color: theme.primaryColor),
    blockSpacing: 8.0,
    listIndent: 24.0,
    listBullet: body,
    listBulletPadding: const EdgeInsets.only(right: 4),
    tableHead: const TextStyle(fontWeight: FontWeight.w600),
    tableBody: body,
    tableHeadAlign: TextAlign.center,
    tablePadding: const EdgeInsets.only(bottom: 4.0),
    tableBorder: TableBorder.all(color: theme.dividerColor),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    tableCellsDecoration: const BoxDecoration(),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    blockquoteDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(3),
      border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
    ),
    codeblockPadding: const EdgeInsets.all(8.0),
    codeblockDecoration: BoxDecoration(color: theme.cardTheme.color ?? theme.cardColor, borderRadius: BorderRadius.circular(2.0)),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(width: 5.0, color: theme.dividerColor)),
    ),
  );
}
