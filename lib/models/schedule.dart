import 'attraction_ref.dart';
import 'programm_entry.dart';
import 'programm_point.dart';

/// A single programm entry paired with the attraction it belongs to.
class ScheduleItem {
  final ProgrammEntry entry;
  final AttractionRef attraction;

  const ScheduleItem({required this.entry, required this.attraction});
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

/// Groups programm points (from `GET /api/v1/programm` or `/api/v1/event`)
/// into days, sorted chronologically by date then start time.
///
/// With [mostRecentFirst] the whole order is reversed — days and the items
/// within each day — which is how the website lists its "Vergangene" group.
List<ScheduleDay> buildSchedule(List<ProgrammPoint> points, {bool mostRecentFirst = false}) {
  final byDay = <DateTime, List<ScheduleItem>>{};

  for (final point in points) {
    final entry = point.entry;
    final key = _dayKey(entry.fromDate);
    byDay.putIfAbsent(key, () => []).add(ScheduleItem(entry: entry, attraction: point.attraction));
  }

  final days = byDay.keys.toList()..sort();
  final schedule = days.map((day) {
    final items = byDay[day]!
      ..sort((a, b) {
        final t = _timeRank(a.entry.fromTime).compareTo(_timeRank(b.entry.fromTime));
        if (t != 0) return t;
        return a.attraction.name.toLowerCase().compareTo(b.attraction.name.toLowerCase());
      });
    return ScheduleDay(date: day, items: mostRecentFirst ? items.reversed.toList() : items);
  }).toList();
  return mostRecentFirst ? schedule.reversed.toList() : schedule;
}
