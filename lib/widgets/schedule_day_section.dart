import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils/formatting.dart';
import 'programm_entry_tile.dart';

/// A sectioned day of the schedule: a day header (weekday emphasized, date
/// secondary — like the website's day divider) followed by its rows. Shared by
/// the Programm, Wirtschaft/Gewerbe and Favoriten screens.
class ScheduleDaySection extends StatelessWidget {
  const ScheduleDaySection({super.key, required this.day, required this.onTapItem, this.past = false, this.showFavorite = true});

  final ScheduleDay day;
  final void Function(ScheduleItem item) onTapItem;

  /// Renders the day muted, for the "Vergangene" group.
  final bool past;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = past ? theme.colorScheme.outline : theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatWeekday(day.date).toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: accent),
              ),
              const SizedBox(width: 8),
              Text(formatDateShort(day.date), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        for (final item in day.items) ProgrammEntryTile(item: item, past: past, showFavorite: showFavorite, onTap: () => onTapItem(item)),
      ],
    );
  }
}
