import 'package:flutter/material.dart';

import '../api/meetup_api.dart';
import '../models/meetup.dart';
import '../widgets/async_view.dart';

/// Jahrgangstreffen in the app is only the public participant list (website:
/// `jahrgangstreffen/liste.vue`) — pick a Jahrgang, see who signed up for it.
/// Registration is website-only; the app deliberately does not link to it.
class JahrgangstreffenScreen extends StatefulWidget {
  const JahrgangstreffenScreen({super.key});

  @override
  State<JahrgangstreffenScreen> createState() => _JahrgangstreffenScreenState();
}

class _JahrgangstreffenScreenState extends State<JahrgangstreffenScreen> {
  final _api = MeetupApi();
  late Future<List<MeetupEntry>> _future;
  MeetupJahrgang? _group;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchEntries();
  }

  void _reload() => setState(() {
    _future = _api.fetchEntries();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Teilnehmerliste')),
      body: AsyncView<List<MeetupEntry>>(
        future: _future,
        onRetry: _reload,
        onData: (context, all) {
          final entries = _group == null
              ? <MeetupEntry>[]
              : (all.where((e) => e.jahrgang == _group).toList()..sort((a, b) {
                  final l = a.lastname.compareTo(b.lastname);
                  return l != 0 ? l : a.firstname.compareTo(b.firstname);
                }));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<MeetupJahrgang>(
                initialValue: _group,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Jahrgang', border: OutlineInputBorder()),
                hint: const Text('Jahrgang wählen…'),
                items: [
                  for (final j in MeetupJahrgang.values)
                    DropdownMenuItem(
                      value: j,
                      child: Text(j.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _group = v),
              ),
              const SizedBox(height: 16),
              if (_group != null && entries.isEmpty)
                Text('Noch keine Anmeldungen für diese Gruppe.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
              if (entries.isNotEmpty) ...[
                Text(
                  '${entries.length} ${entries.length == 1 ? 'Anmeldung' : 'Anmeldungen'}'.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                for (final e in entries) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${e.lastname}, ${e.firstname}')),
              ],
            ],
          );
        },
      ),
    );
  }
}
