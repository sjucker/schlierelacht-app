/// How important a [Message] is, from most to least important.
enum MessagePriority {
  /// Notfall — an emergency alert.
  high,

  /// Warnung.
  medium,

  /// Info.
  low;

  /// Unknown values (added by a later backend) count as [low], so an old
  /// build still shows the message instead of failing.
  static MessagePriority fromJson(String? value) => switch (value) {
    'HIGH' => high,
    'MEDIUM' => medium,
    _ => low,
  };
}

/// A Meldung — an emergency alert, warning or info, written in the admin UI.
/// Mirrors the backend `MessageDTO` (schlierelacht-admin).
///
/// Keep in sync with ch.schlierelacht.admin.dto.MessageDTO — there is no code
/// generator for the Flutter app (unlike the website's generated rest.ts).
///
/// The backend returns the active messages most important first (priority,
/// then newest), so the app shows the first one on the home screen and keeps
/// that order everywhere.
class Message {
  final int id;
  final MessagePriority priority;
  final String title;

  /// Markdown.
  final String content;
  final DateTime createdAt;

  const Message({required this.id, required this.priority, required this.title, required this.content, required this.createdAt});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as int,
    priority: MessagePriority.fromJson(json['priority'] as String?),
    title: json['title'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
