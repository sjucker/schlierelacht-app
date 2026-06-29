/// Mirrors the backend `ImageType` enum.
enum ImageType { main, additional, unknown }

ImageType _imageTypeFromJson(String? value) {
  switch (value) {
    case 'MAIN':
      return ImageType.main;
    case 'ADDITIONAL':
      return ImageType.additional;
    default:
      return ImageType.unknown;
  }
}

/// Mirrors the backend `ImageDTO`.
class ImageRef {
  final String cloudflareId;
  final String description;
  final ImageType type;

  const ImageRef({
    required this.cloudflareId,
    required this.description,
    required this.type,
  });

  factory ImageRef.fromJson(Map<String, dynamic> json) => ImageRef(
        cloudflareId: json['cloudflareId'] as String,
        description: (json['description'] as String?) ?? '',
        type: _imageTypeFromJson(json['type'] as String?),
      );
}
