/// Mirrors the backend `AttractionFileDTO` — a downloadable file attached to an
/// attraction, served at `/api/v1/attraction/{externalId}/files/{id}`.
class AttractionFile {
  final int id;
  final String filename;
  final String filetype;
  final String description;
  final int filesize;

  const AttractionFile({
    required this.id,
    required this.filename,
    required this.filetype,
    required this.description,
    required this.filesize,
  });

  factory AttractionFile.fromJson(Map<String, dynamic> json) => AttractionFile(
        id: json['id'] as int,
        filename: json['filename'] as String,
        filetype: json['filetype'] as String,
        description: json['description'] as String,
        filesize: (json['filesize'] as num).toInt(),
      );
}
