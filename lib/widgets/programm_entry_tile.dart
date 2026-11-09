import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils/formatting.dart';
import 'favorite_button.dart';

/// A single schedule row: start time, act name and location. [past] rows are
/// muted, like the website's "Vergangene" group.
class ProgrammEntryTile extends StatelessWidget {
  const ProgrammEntryTile({
    super.key,
    required this.item,
    required this.onTap,
    this.past = false,
    this.showFavorite = true,
  });

  final ScheduleItem item;
  final VoidCallback onTap;
  final bool past;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = formatTime(item.entry.fromTime);

    return Opacity(
      opacity: past ? 0.6 : 1,
      child: ListTile(
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
        trailing: showFavorite
            ? FavoriteButton(externalId: item.attraction.externalId)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
