import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../api/message_api.dart';
import '../models/message.dart';
import '../screens/message_detail_screen.dart';
import '../screens/messages_screen.dart';
import '../utils/external_links.dart';
import '../utils/formatting.dart';
import '../utils/markdown_style.dart';

/// The most important active Meldung on the landing page, below the logo (the
/// backend's first entry: highest priority, then most recently published). Shows only its
/// title; a tap opens [MessageDetailScreen], the "Alle Meldungen" link below
/// opens [MessagesScreen]. Not dismissible: it stays as long as it is active.
///
/// Reloaded every 2 minutes and when the app returns to the foreground, so a
/// new alert shows up without a restart (cache fallback included, so it works
/// offline). Takes no space when there is no active message, while loading, or
/// when loading fails.
class MessageCard extends StatefulWidget {
  const MessageCard({super.key, this.api});

  /// For tests; defaults to a real [MessageApi].
  final MessageApi? api;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  static const _refresh = Duration(minutes: 2);

  late final MessageApi _api = widget.api ?? MessageApi();
  List<Message> _messages = const [];
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_refresh, (_) => _load());
    _lifecycle = AppLifecycleListener(onResume: _load);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final messages = await _api.fetchActive();
      if (mounted) setState(() => _messages = messages);
    } catch (_) {
      // Keep what is shown; with nothing loaded yet the card stays hidden.
    }
  }

  void _openAll() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MessagesScreen()));

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) return const SizedBox.shrink();
    final count = _messages.length;
    return Padding(
      // 20 = the 16 around the home screen's cards + the 4 default Card margin
      // they keep (MessageTitleCard has none), so all edges line up.
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MessageTitleCard(message: _messages.first, onTap: () => openMessage(context, _messages.first)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right),
              label: Text(count > 1 ? 'Alle Meldungen ($count)' : 'Alle Meldungen'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens [MessageDetailScreen] for [message].
void openMessage(BuildContext context, Message message) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MessageDetailScreen(message: message)));

/// A Meldung reduced to its title: priority icon, title, chevron, in the
/// priority's colors. Tapping opens the full message.
class MessageTitleCard extends StatelessWidget {
  const MessageTitleCard({super.key, required this.message, required this.onTap});

  final Message message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = MessageStyle.of(message.priority, theme.colorScheme);
    return Card(
      color: style.background,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Semantics(
                label: style.label,
                child: Icon(style.icon, color: style.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.title,
                  style: theme.textTheme.titleMedium?.copyWith(color: style.foreground, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.chevron_right, color: style.foreground),
            ],
          ),
        ),
      ),
    );
  }
}

/// One Meldung in full as a colored card: icon + priority label, title,
/// markdown content. Used by [MessagesScreen] and [MessageDetailScreen].
class MessageBox extends StatelessWidget {
  const MessageBox({super.key, required this.message, this.onTap, this.showPublishedAt = false});

  final Message message;
  final VoidCallback? onTap;

  /// "Veröffentlicht am 03.09.2027, 18:30" below the title (the detail screen).
  final bool showPublishedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = MessageStyle.of(message.priority, theme.colorScheme);
    final text = theme.textTheme;
    return Card(
      color: style.background,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(style.icon, color: style.foreground, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    style.label.toUpperCase(),
                    style: text.labelMedium?.copyWith(color: style.foreground, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.title,
                style: text.titleMedium?.copyWith(color: style.foreground, fontWeight: FontWeight.bold),
              ),
              if (showPublishedAt) ...[
                const SizedBox(height: 2),
                Text(
                  'Veröffentlicht am ${formatDateTimeShort(message.publishedAt)}',
                  style: text.bodySmall?.copyWith(color: style.foreground.withValues(alpha: 0.8)),
                ),
              ],
              const SizedBox(height: 4),
              MarkdownBody(
                data: message.content,
                onTapLink: (_, href, _) => openUrl(href),
                // Every markdown element (headings, bold, lists, quotes, tables, …)
                // in the priority's text color: recolor the whole text theme
                // rather than single elements, which left headings black.
                styleSheet:
                    markdownStyleSheet(
                      theme.copyWith(
                        textTheme: text.apply(bodyColor: style.foreground, displayColor: style.foreground),
                      ),
                    ).copyWith(
                      a: text.bodyMedium?.copyWith(color: style.foreground, decoration: TextDecoration.underline, decorationColor: style.foreground),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colors, icon and label per [MessagePriority]: an emergency in strong red,
/// a warning in amber, an info in the logo's light blue tint.
class MessageStyle {
  const MessageStyle._(this.label, this.icon, this.background, this.foreground);

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  static const _amber = Color(0xFFFFE0A3);
  static const _onAmber = Color(0xFF4A2C00);

  static MessageStyle of(MessagePriority priority, ColorScheme colors) => switch (priority) {
    MessagePriority.high => MessageStyle._('Notfall', Icons.report, colors.error, colors.onError),
    MessagePriority.medium => const MessageStyle._('Warnung', Icons.warning_amber, _amber, _onAmber),
    MessagePriority.low => MessageStyle._('Info', Icons.info_outline, colors.secondaryContainer, colors.onSecondaryContainer),
  };
}
