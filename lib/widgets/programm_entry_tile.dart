import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils/formatting.dart';
import 'favorite_button.dart';

/// A single schedule row: start time, act name and location. [past] rows are
/// muted, like the website's "Vergangene" group.
class ProgrammEntryTile extends StatelessWidget {
  const ProgrammEntryTile({super.key, required this.item, required this.onTap, this.past = false, this.live = false, this.showFavorite = true, this.subtitle});

  final ScheduleItem item;
  final VoidCallback onTap;
  final bool past;

  /// On stage right now: a "Jetzt" marker after the name.
  final bool live;
  final bool showFavorite;

  /// Replaces the location line, e.g. with "Hauptbühne · bis 22:00".
  final String? subtitle;

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
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
        ),
        title: live
            ? Row(
                children: [
                  Flexible(child: Text(item.attraction.name)),
                  const SizedBox(width: 8),
                  const LiveMarker(),
                ],
              )
            : Text(item.attraction.name),
        subtitle: Text(subtitle ?? item.entry.location.name),
        trailing: showFavorite ? FavoriteButton(externalId: item.attraction.externalId) : const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// "● JETZT": the red dot of the landing page's "Jetzt läuft" heading, on a
/// row that is on stage right now.
class LiveMarker extends StatelessWidget {
  const LiveMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Semantics(
      label: 'läuft gerade',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            'JETZT',
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: color),
          ),
        ],
      ),
    );
  }
}
