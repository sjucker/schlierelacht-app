import 'package:flutter/material.dart';

import '../models/programm_point.dart';
import '../models/schedule.dart';
import 'schedule_day_section.dart';

/// Slivers for a schedule split the way the website lists it: upcoming entries
/// in chronological order (next one on top), then a "Vergangene" group with
/// past entries most-recent first. The split uses the backend's `past` flag.
List<Widget> scheduleSlivers({required List<ProgrammPoint> points, required void Function(ScheduleItem item) onTapItem, bool showFavorite = true}) {
  final upcoming = buildSchedule(points.where((p) => !p.entry.past).toList());
  final past = buildSchedule(points.where((p) => p.entry.past).toList(), mostRecentFirst: true);

  return [
    SliverList.builder(
      itemCount: upcoming.length,
      itemBuilder: (context, i) => ScheduleDaySection(day: upcoming[i], onTapItem: onTapItem, showFavorite: showFavorite),
    ),
    if (past.isNotEmpty) ...[
      const SliverToBoxAdapter(child: _PastHeader()),
      SliverList.builder(
        itemCount: past.length,
        itemBuilder: (context, i) => ScheduleDaySection(day: past[i], onTapItem: onTapItem, showFavorite: showFavorite, past: true),
      ),
    ],
  ];
}

class _PastHeader extends StatelessWidget {
  const _PastHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
      child: Text(
        'VERGANGENE',
        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2, color: theme.colorScheme.outline),
      ),
    );
  }
}
