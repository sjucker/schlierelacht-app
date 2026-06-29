/// Mirrors the backend `NewsDTO` (schlierelacht-admin).
///
/// Keep in sync with ch.schlierelacht.admin.dto.NewsDTO — there is no code
/// generator for the Flutter app (unlike the website's generated rest.ts).
class News {
  final int id;
  final DateTime date;
  final String title;
  final String introText;
  final String fullText;
  final String? cloudflareId;

  const News({
    required this.id,
    required this.date,
    required this.title,
    required this.introText,
    required this.fullText,
    this.cloudflareId,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String,
        introText: json['introText'] as String,
        fullText: json['fullText'] as String,
        cloudflareId: json['cloudflareId'] as String?,
      );
}
