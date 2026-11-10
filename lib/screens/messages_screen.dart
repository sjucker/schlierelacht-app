import 'package:flutter/material.dart';

import '../api/message_api.dart';
import '../models/message.dart';
import '../widgets/async_view.dart';
import '../widgets/message_card.dart';

/// Meldungen: every active message, most important first (the backend's
/// order: priority, then most recently published). Opened from the landing page's message card
/// and from a push with route `meldungen`.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.api});

  /// For tests; defaults to a real [MessageApi].
  final MessageApi? api;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final MessageApi _api = widget.api ?? MessageApi();
  late Future<List<Message>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchActive();
  }

  void _reload() => setState(() {
    _future = _api.fetchActive();
  });

  /// Pull-to-refresh: the indicator spins until the new data is in, while
  /// the current list stays on screen (see [AsyncView]).
  Future<void> _refresh() {
    _reload();
    return settled(_future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meldungen')),
      body: AsyncView<List<Message>>(
        future: _future,
        onRetry: _reload,
        onData: (context, messages) => RefreshIndicator(
          onRefresh: _refresh,
          child: messages.isEmpty
              // Scrollable, so pull-to-refresh works on the empty state too.
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Im Moment gibt es keine Meldungen.', textAlign: TextAlign.center),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => MessageBox(message: messages[i]),
                ),
        ),
      ),
    );
  }
}
