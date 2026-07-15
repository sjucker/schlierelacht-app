import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils/formatting.dart';
import 'favorite_button.dart';

/// A single schedule row: start time, artist name and location.
class ProgrammEntryTile extends StatelessWidget {
  const ProgrammEntryTile({super.key, required this.item, required this.onTap});

  final ScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = formatTime(item.entry.fromTime);

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        child: Text(
          time.isEmpty ? '–' : time,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      title: Text(item.attraction.name),
      subtitle: Text(item.entry.location.name),
      trailing: FavoriteButton(externalId: item.attraction.externalId),
    );
  }
}
