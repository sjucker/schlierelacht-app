import 'package:material_ui/material_ui.dart';

import '../api/ok_api.dart';
import '../models/ok.dart';
import '../utils/external_links.dart';
import '../widgets/cloudflare_image.dart';

/// "Über uns" (website: `info.vue`): the Geschäftsstelle contact, the
/// organizing committee (OK) with portraits, and the OK teams' members.
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final _api = OkApi();
  late Future<Ok> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchOk();
  }

  void _reload() => setState(() {
    _future = _api.fetchOk();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary);
    return Scaffold(
      appBar: AppBar(title: const Text('Über uns')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Geschäftsstelle/Sekretariat', style: heading),
          const SizedBox(height: 8),
          const _ContactCard(),
          const SizedBox(height: 24),
          Text('Organisations-Komitee', style: heading),
          const SizedBox(height: 8),
          // The static contact above stays visible while the OK loads or fails.
          FutureBuilder<Ok>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  children: [
                    const Text('Inhalt konnte nicht geladen werden.'),
                    const SizedBox(height: 8),
                    FilledButton.tonal(onPressed: _reload, child: const Text('Erneut versuchen')),
                  ],
                );
              }
              return _OkContent(ok: snapshot.data!, heading: heading);
            },
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const ListTile(leading: Icon(Icons.person_outline), title: Text('Erika und Charly Mettier'), subtitle: Text('Kampstrasse 6, 8952 Schlieren')),
          ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('079 456 79 69'), onTap: () => openUrl('tel:+41794567969')),
          ListTile(leading: const Icon(Icons.mail_outline), title: const Text('info@schlierelacht.ch'), onTap: () => openUrl('mailto:info@schlierelacht.ch')),
        ],
      ),
    );
  }
}

class _OkContent extends StatelessWidget {
  const _OkContent({required this.ok, required this.heading});

  final Ok ok;
  final TextStyle? heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byTeam = <OkTeam, List<OkTeamMember>>{};
    for (final m in ok.teamMembers) {
      final team = m.team;
      if (team != null) byTeam.putIfAbsent(team, () => []).add(m);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final member in ok.members) _PersonCard(member: member),
        if (byTeam.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('OK Team-Mitglieder', style: heading),
          // Enum declaration order == the website's TEAM_ORDER.
          for (final team in OkTeam.values)
            if (byTeam[team] case final members?) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  team.label,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                ),
              ),
              for (final m in members)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Wrap(
                    children: [
                      Text(m.name),
                      if (m.email != null && m.email!.isNotEmpty)
                        InkWell(
                          onTap: () => openUrl('mailto:${m.email}'),
                          child: Text(', ${m.email}', style: TextStyle(color: theme.colorScheme.outline)),
                        ),
                    ],
                  ),
                ),
            ],
        ],
      ],
    );
  }
}

/// A committee member: portrait, name, role and e-mail (website: `PersonCard`).
class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.member});

  final OkMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = member.email;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(width: 96, height: 112, child: CloudflareImage(cloudflareId: member.cloudflareId)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(member.role, style: theme.textTheme.bodyMedium),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => openUrl('mailto:$email'),
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
