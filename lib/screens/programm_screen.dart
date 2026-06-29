import 'package:flutter/material.dart';

import '../api/artist_api.dart';
import '../models/attraction.dart';
import '../models/schedule.dart';
import '../utils/formatting.dart';
import '../widgets/async_view.dart';
import '../widgets/programm_entry_tile.dart';
import 'artist_detail_screen.dart';

class ProgrammScreen extends StatefulWidget {
  const ProgrammScreen({super.key});

  @override
  State<ProgrammScreen> createState() => _ProgrammScreenState();
}

class _ProgrammScreenState extends State<ProgrammScreen> {
  final _api = ArtistApi();
  late Future<List<Attraction>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchArtists();
  }

  void _reload() => setState(() => _future = _api.fetchArtists());

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Attraction>>(
      future: _future,
      onRetry: _reload,
      onData: (context, attractions) {
        final days = buildSchedule(attractions);
        if (days.isEmpty) {
          return const Center(child: Text('Das Programm folgt in Kürze.'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, i) => _DaySection(
              day: days[i],
              onTapItem: (item) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ArtistDetailScreen(externalId: item.artist.externalId),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.onTapItem});

  final ScheduleDay day;
  final void Function(ScheduleItem item) onTapItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            formatGermanDate(day.date),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (final item in day.items)
          ProgrammEntryTile(item: item, onTap: () => onTapItem(item)),
      ],
    );
  }
}
