import 'package:flutter/material.dart';

import '../api/programm_api.dart';
import '../models/programm_point.dart';
import '../models/schedule.dart';
import '../services/prefs.dart';
import '../widgets/async_view.dart';
import '../widgets/schedule_day_section.dart';
import 'attraction_detail_screen.dart';
import 'notification_settings_screen.dart';

/// The user's favorited acts as a schedule: the full programm filtered down to
/// favorited attractions (by `externalId`), grouped per day. Updates live when
/// a favorite is toggled anywhere via the favorites [ValueNotifier].
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _api = ProgrammApi();
  late Future<List<ProgrammPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchProgramm();
  }

  void _reload() => setState(() {
    _future = _api.fetchProgramm();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriten'),
        actions: [
          IconButton(
            tooltip: 'Erinnerungen',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen())),
          ),
        ],
      ),
      body: AsyncView<List<ProgrammPoint>>(
        future: _future,
        onRetry: _reload,
        onData: (context, points) {
          return ValueListenableBuilder<Set<String>>(
            valueListenable: Prefs.instance.favorites,
            builder: (context, favorites, _) {
              final days = buildSchedule(points.where((p) => favorites.contains(p.attraction.externalId)).toList());
              if (days.isEmpty) return const _EmptyFavorites();
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.builder(
                  itemCount: days.length,
                  itemBuilder: (context, i) => ScheduleDaySection(
                    day: days[i],
                    onTapItem: (item) =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttractionDetailScreen(externalId: item.attraction.externalId))),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            const Text('Noch keine Favoriten.\nTippe im Programm auf das Herz, um Acts zu speichern.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
