import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../api/message_api.dart';
import '../models/message.dart';
import '../screens/messages_screen.dart';
import '../utils/external_links.dart';

/// The most important active Meldung at the top of the landing page (the
/// backend's first entry: highest priority, then newest). Links to all of them
/// on [MessagesScreen] when there are more. Not dismissible: it stays as long
/// as it is active.
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
    final more = _messages.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: MessageBox(message: _messages.first, onTap: _openAll, footer: more ? 'Alle Meldungen (${_messages.length})' : null),
    );
  }
}

/// One Meldung as a colored card: icon + priority label, title, markdown
/// content. Shared by the landing page and [MessagesScreen].
class MessageBox extends StatelessWidget {
  const MessageBox({super.key, required this.message, this.onTap, this.footer});

  final Message message;
  final VoidCallback? onTap;

  /// A link-styled line at the bottom, e.g. "Alle Meldungen (3)".
  final String? footer;

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
              const SizedBox(height: 4),
              MarkdownBody(
                data: message.content,
                onTapLink: (_, href, _) => openUrl(href),
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: text.bodyMedium?.copyWith(color: style.foreground),
                  listBullet: text.bodyMedium?.copyWith(color: style.foreground),
                  a: text.bodyMedium?.copyWith(color: style.foreground, decoration: TextDecoration.underline, decorationColor: style.foreground),
                ),
              ),
              if (footer case final footer?) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      footer,
                      style: text.labelLarge?.copyWith(color: style.foreground, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.chevron_right, color: style.foreground),
                  ],
                ),
              ],
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
