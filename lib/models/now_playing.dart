import 'programm_entry.dart';
import 'programm_point.dart';
import 'schedule.dart';

/// What is on right now and what starts next — the landing page's
/// "Jetzt läuft" card. See [nowAndNext].
class NowAndNext {
  final List<ScheduleItem> now;
  final List<ScheduleItem> next;

  const NowAndNext({required this.now, required this.next});

  bool get isEmpty => now.isEmpty && next.isEmpty;
}

/// Splits the programm into the entries running at [now] and the next
/// [nextLimit] that start within [nextWindow] (so the card stays hidden
/// between festival days instead of announcing something weeks away).
///
/// Entries without a start time (all-day) are left out. The end is `toTime`
/// on `toDate` (or the start day; an end at or before the start means past
/// midnight), the end of `toDate` when only that is set, and otherwise
/// [assumedLength] after the start. Times are the programm's local
/// wall-clock times, compared with the device clock.
NowAndNext nowAndNext(
  List<ProgrammPoint> points,
  DateTime now, {
  int nextLimit = 3,
  Duration nextWindow = const Duration(hours: 12),
  Duration assumedLength = const Duration(hours: 1),
}) {
  final running = <(DateTime, ScheduleItem)>[];
  final upcoming = <(DateTime, ScheduleItem)>[];
  for (final p in points) {
    final start = _at(p.entry.fromDate, p.entry.fromTime);
    if (start == null) continue;
    final item = ScheduleItem(entry: p.entry, attraction: p.attraction);
    if (start.isAfter(now)) {
      if (!start.isAfter(now.add(nextWindow))) upcoming.add((start, item));
    } else if (now.isBefore(_end(p.entry, start, assumedLength))) {
      running.add((start, item));
    }
  }
  int byStart((DateTime, ScheduleItem) a, (DateTime, ScheduleItem) b) => a.$1.compareTo(b.$1);
  running.sort(byStart);
  upcoming.sort(byStart);
  return NowAndNext(now: [for (final (_, item) in running) item], next: [for (final (_, item) in upcoming.take(nextLimit)) item]);
}

/// Whether [entry] is on at [now], by the same rule as [nowAndNext]: started,
/// and its end (see there) not yet reached. All-day entries never are.
bool isRunningAt(ProgrammEntry entry, DateTime now, {Duration assumedLength = const Duration(hours: 1)}) {
  final start = _at(entry.fromDate, entry.fromTime);
  return start != null && !start.isAfter(now) && now.isBefore(_end(entry, start, assumedLength));
}

DateTime _end(ProgrammEntry entry, DateTime start, Duration assumedLength) {
  final toDate = entry.toDate;
  final toTime = _at(toDate ?? entry.fromDate, entry.toTime);
  if (toTime != null) {
    return toTime.isAfter(start) ? toTime : toTime.add(const Duration(days: 1));
  }
  if (toDate != null) return DateTime(toDate.year, toDate.month, toDate.day + 1);
  return start.add(assumedLength);
}

/// [day] at the `HH:MM[:SS]` [time], or null without a (valid) time.
DateTime? _at(DateTime day, String? time) {
  final parts = time?.split(':');
  if (parts == null || parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(day.year, day.month, day.day, h, m);
}
