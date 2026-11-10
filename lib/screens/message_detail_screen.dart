import 'package:flutter/material.dart';

import '../models/message.dart';
import '../widgets/message_card.dart';

/// One Meldung in full: priority, title, when it was published and the
/// markdown content. Opened from the
/// landing page's message card and from [MessagesScreen]. Shows the message it
/// was given (there is no detail endpoint; the list already holds everything).
class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meldung')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [MessageBox(message: message, showPublishedAt: true)],
      ),
    );
  }
}
