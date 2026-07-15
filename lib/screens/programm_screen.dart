import 'package:flutter/material.dart';

import '../api/programm_api.dart';
import '../models/programm_point.dart';
import '../models/schedule.dart';
import '../widgets/async_view.dart';
import '../widgets/schedule_day_section.dart';
import 'artist_detail_screen.dart';

class ProgrammScreen extends StatefulWidget {
  const ProgrammScreen({super.key});

  @override
  State<ProgrammScreen> createState() => _ProgrammScreenState();
}

class _ProgrammScreenState extends State<ProgrammScreen> {
  final _api = ProgrammApi();
  late Future<List<ProgrammPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchProgramm();
  }

  void _reload() => setState(() => _future = _api.fetchProgramm());

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<ProgrammPoint>>(
      future: _future,
      onRetry: _reload,
      onData: (context, points) {
        final days = buildSchedule(points);
        if (days.isEmpty) {
          return const Center(child: Text('Das Programm folgt in Kürze.'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, i) => ScheduleDaySection(
              day: days[i],
              onTapItem: (item) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ArtistDetailScreen(externalId: item.attraction.externalId),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
