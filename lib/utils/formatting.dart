import 'package:intl/intl.dart';

final DateFormat _germanDate = DateFormat('EEEE, dd.MM.yyyy', 'de_CH');
final DateFormat _weekday = DateFormat('EEEE', 'de_CH');
final DateFormat _dateShort = DateFormat('dd.MM.yyyy', 'de_CH');

/// Formats a date the way the website does, e.g. "Mittwoch, 27.06.2026".
String formatGermanDate(DateTime date) => _germanDate.format(date);

/// Weekday name only, e.g. "Freitag" (website: `format-weekday.ts`).
String formatWeekday(DateTime date) => _weekday.format(date);

/// Date without its weekday, e.g. "03.09.2027" (website: `format-date-short.ts`).
String formatDateShort(DateTime date) => _dateShort.format(date);

/// Trims a raw `HH:MM[:SS]` time string to `HH:MM`. Returns '' for null/empty.
String formatTime(String? time) {
  if (time == null || time.isEmpty) return '';
  final parts = time.split(':');
  if (parts.length < 2) return time;
  return '${parts[0]}:${parts[1]}';
}

/// Human-readable file size (B / KB / MB), mirroring the website and backend.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Upper-cased file extension, e.g. "logo.PDF" → "PDF". Empty when none.
String fileExtension(String filename) {
  final dot = filename.lastIndexOf('.');
  return dot < 0 ? '' : filename.substring(dot + 1).toUpperCase();
}
