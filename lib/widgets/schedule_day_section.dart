import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils/formatting.dart';
import 'programm_entry_tile.dart';

/// A sectioned day of the schedule: a sticky-styled date header followed by its
/// programm rows. Shared by the Programm and Favoriten screens.
class ScheduleDaySection extends StatelessWidget {
  const ScheduleDaySection({
    super.key,
    required this.day,
    required this.onTapItem,
  });

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
