import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../services/push.dart' show scaffoldMessengerKey;
import '../utils/external_links.dart';

/// Social Media: the festival's profiles (the Instagram feed is linked, not
/// embedded — that would need a Meta API token) and a call to post photos with
/// the festival hashtag.
class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  /// Copies the hashtag (Instagram can't be pre-filled with a caption), then
  /// opens Instagram's camera — or the profile in the browser without the app.
  Future<void> _postWithHashtag() async {
    await Clipboard.setData(const ClipboardData(text: instagramHashtag));
    scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('$instagramHashtag kopiert – füge ihn in deinen Post ein.')));
    if (!await openUrl('instagram://camera')) await openUrl(instagramUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Social Media')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zeig uns dein Schlierefäscht!',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onTertiaryContainer),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teile deine Fotos und Videos auf Instagram mit $instagramHashtag '
                    'und markiere @schlierelacht.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(onPressed: _postWithHashtag, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Foto posten')),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(const ClipboardData(text: instagramHashtag));
                          scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('$instagramHashtag kopiert')));
                        },
                        icon: const Icon(Icons.tag),
                        label: const Text('Hashtag kopieren'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileTile(icon: Icons.camera_alt_outlined, title: 'Instagram', subtitle: 'Fotos, Reels und News im Feed von @schlierelacht', url: instagramUrl),
          _ProfileTile(icon: Icons.facebook, title: 'Facebook', subtitle: 'Events und Neuigkeiten', url: facebookUrl),
          _ProfileTile(icon: Icons.work_outline, title: 'LinkedIn', subtitle: 'Verein und Sponsoring', url: linkedinUrl),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.subtitle, required this.url});

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => openUrl(url),
    ),
  );
}
