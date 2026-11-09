/// Mirrors the backend `DownloadCategory` enum, in the website's display order,
/// with German section labels.
enum DownloadCategory {
  logos('LOGOS', 'Logos'),
  sponsoring('SPONSORING', 'Sponsoring'),
  gastronomie('GASTRONOMIE', 'Gastronomie'),
  programm('PROGRAMM', 'Programm'),
  unknown('', 'Weitere');

  const DownloadCategory(this.wire, this.label);

  final String wire;
  final String label;

  static DownloadCategory fromWire(String? value) => values.firstWhere((c) => c.wire == value, orElse: () => DownloadCategory.unknown);
}

/// Mirrors the backend `DownloadDTO` — a public file, served at
/// `/api/v1/downloads/{id}/file`.
class Download {
  final int id;
  final String filename;
  final String filetype;
  final String description;
  final int filesize;
  final DownloadCategory category;

  const Download({required this.id, required this.filename, required this.filetype, required this.description, required this.filesize, required this.category});

  factory Download.fromJson(Map<String, dynamic> json) => Download(
    id: json['id'] as int,
    filename: json['filename'] as String,
    filetype: json['filetype'] as String,
    description: json['description'] as String,
    filesize: (json['filesize'] as num).toInt(),
    category: DownloadCategory.fromWire(json['category'] as String?),
  );
}
