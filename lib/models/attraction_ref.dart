/// Mirrors the backend `AttractionRefDTO` — a lightweight attraction reference
/// (just enough to label and link a programm point). See [ProgrammPoint].
class AttractionRef {
  final String externalId;
  final String name;

  const AttractionRef({required this.externalId, required this.name});

  factory AttractionRef.fromJson(Map<String, dynamic> json) => AttractionRef(externalId: json['externalId'] as String, name: json['name'] as String);
}
