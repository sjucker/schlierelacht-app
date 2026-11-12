/// One FAQ question with its answer (markdown). Mirrors the backend
/// `FaqEntryDTO` (schlierelacht-admin).
///
/// Keep in sync with ch.schlierelacht.admin.dto.FaqEntryDTO / FaqGroupDTO —
/// there is no code generator for the Flutter app (unlike the website's
/// generated rest.ts).
class FaqEntry {
  final int id;

  /// The question.
  final String title;

  /// The answer, markdown.
  final String content;

  const FaqEntry({required this.id, required this.title, required this.content});

  factory FaqEntry.fromJson(Map<String, dynamic> json) => FaqEntry(id: json['id'] as int, title: json['title'] as String, content: json['content'] as String);
}

/// The FAQ entries sharing a group name. The backend sends groups and entries
/// in display order (groups by their lowest sort number, entries by number,
/// then title); the app keeps it.
class FaqGroup {
  final String name;
  final List<FaqEntry> entries;

  const FaqGroup({required this.name, required this.entries});

  factory FaqGroup.fromJson(Map<String, dynamic> json) =>
      FaqGroup(name: json['name'] as String, entries: (json['entries'] as List<dynamic>).map((e) => FaqEntry.fromJson(e as Map<String, dynamic>)).toList());
}
