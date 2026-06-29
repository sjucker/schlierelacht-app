import 'package:intl/intl.dart';

final DateFormat _germanDate = DateFormat('EEEE, dd.MM.yyyy', 'de_CH');

/// Formats a date the way the website does, e.g. "Mittwoch, 27.06.2026".
String formatGermanDate(DateTime date) => _germanDate.format(date);

/// Trims a raw `HH:MM[:SS]` time string to `HH:MM`. Returns '' for null/empty.
String formatTime(String? time) {
  if (time == null || time.isEmpty) return '';
  final parts = time.split(':');
  if (parts.length < 2) return time;
  return '${parts[0]}:${parts[1]}';
}
