import 'attraction.dart';
import 'programm_entry.dart';

/// A single programm entry paired with the artist/attraction it belongs to.
class ScheduleItem {
  final ProgrammEntry entry;
  final Attraction artist;

  const ScheduleItem({required this.entry, required this.artist});
}

/// One day of the festival schedule.
class ScheduleDay {
  final DateTime date;
  final List<ScheduleItem> items;

  const ScheduleDay({required this.date, required this.items});
}

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

int _timeRank(String? hhmm) {
  // Entries without a time sort first within their day.
  if (hhmm == null || hhmm.isEmpty) return -1;
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return h * 60 + m;
}

/// Flattens every attraction's programm entries into a schedule grouped by day,
/// sorted chronologically by date then start time. Mirrors how the website
/// assembles the "Programm" from `/api/artist` data.
List<ScheduleDay> buildSchedule(List<Attraction> attractions) {
  final byDay = <DateTime, List<ScheduleItem>>{};

  for (final artist in attractions) {
    for (final entry in artist.programm) {
      final key = _dayKey(entry.fromDate);
      byDay
          .putIfAbsent(key, () => [])
          .add(ScheduleItem(entry: entry, artist: artist));
    }
  }

  final days = byDay.keys.toList()..sort();
  return days.map((day) {
    final items = byDay[day]!
      ..sort((a, b) {
        final t = _timeRank(a.entry.fromTime).compareTo(_timeRank(b.entry.fromTime));
        if (t != 0) return t;
        return a.artist.name.toLowerCase().compareTo(b.artist.name.toLowerCase());
      });
    return ScheduleDay(date: day, items: items);
  }).toList();
}
