import 'attraction_ref.dart';
import 'programm_entry.dart';

/// Mirrors the backend `ProgrammPointDTO`: one programm entry joined with the
/// attraction it belongs to. Returned by `GET /api/v1/programm` as a flat,
/// chronologically ordered schedule (so the schedule no longer has to be
/// assembled client-side from `/api/v1/attraction`).
class ProgrammPoint {
  final AttractionRef attraction;
  final ProgrammEntry entry;

  const ProgrammPoint({required this.attraction, required this.entry});

  factory ProgrammPoint.fromJson(Map<String, dynamic> json) => ProgrammPoint(
    attraction: AttractionRef.fromJson(json['attraction'] as Map<String, dynamic>),
    entry: ProgrammEntry.fromJson(json['entry'] as Map<String, dynamic>),
  );
}
