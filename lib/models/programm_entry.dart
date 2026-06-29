import 'location.dart';

/// Mirrors the backend `ProgrammEntryDTO`.
///
/// `fromTime`/`toTime` are kept as raw `HH:MM` strings (formatted for display
/// via utils/formatting.dart); dates are parsed to [DateTime].
class ProgrammEntry {
  final Location location;
  final DateTime fromDate;
  final String? fromTime;
  final DateTime? toDate;
  final String? toTime;

  const ProgrammEntry({
    required this.location,
    required this.fromDate,
    this.fromTime,
    this.toDate,
    this.toTime,
  });

  factory ProgrammEntry.fromJson(Map<String, dynamic> json) => ProgrammEntry(
        location:
            Location.fromJson(json['location'] as Map<String, dynamic>),
        fromDate: DateTime.parse(json['fromDate'] as String),
        fromTime: json['fromTime'] as String?,
        toDate: json['toDate'] == null
            ? null
            : DateTime.parse(json['toDate'] as String),
        toTime: json['toTime'] as String?,
      );
}
