import 'package:flutter/material.dart';

import '../models/now_playing.dart';
import '../models/schedule.dart';
import '../utils/formatting.dart';
import '../utils/minute_clock.dart';
import 'programm_entry_tile.dart';

/// A sectioned day of the schedule: a day header (weekday emphasized, date
/// secondary — like the website's day divider) followed by its rows. Shared by
/// the Programm and Favoriten screens.
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
    // "HEUTE" and "Jetzt" follow the clock while the screen is open.
    return ListenableBuilder(
      listenable: minuteClock,
      builder: (context, _) {
        final now = DateTime.now();
        final today = !past && day.date.year == now.year && day.date.month == now.month && day.date.day == now.day;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              // Upcoming days get the light-blue brand tint; past days stay muted.
              color: past ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.secondaryContainer,
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
                  if (today) ...[const SizedBox(width: 8), const _TodayLabel()],
                ],
              ),
            ),
            for (final item in day.items)
              ProgrammEntryTile(item: item, past: past, live: !past && isRunningAt(item.entry, now), showFavorite: showFavorite, onTap: () => onTapItem(item)),
          ],
        );
      },
    );
  }
}

/// The yellow "HEUTE" next to today's date (logo yellow, like the countdown).
class _TodayLabel extends StatelessWidget {
  const _TodayLabel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(4)),
      child: Text(
        'HEUTE',
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: theme.colorScheme.onTertiaryContainer),
      ),
    );
  }
}
