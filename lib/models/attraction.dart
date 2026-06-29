import 'image_ref.dart';
import 'programm_entry.dart';
import 'tag.dart';

/// Mirrors the backend `AttractionDTO`. Carries its own `programm` entries —
/// the festival schedule is assembled client-side from these (see schedule.dart).
class Attraction {
  final String externalId;
  final String name;
  final String description;
  final String? website;
  final String? instagram;
  final String? facebook;
  final String? youtube;
  final List<ImageRef> images;
  final List<Tag> tags;
  final List<ProgrammEntry> programm;

  const Attraction({
    required this.externalId,
    required this.name,
    required this.description,
    this.website,
    this.instagram,
    this.facebook,
    this.youtube,
    required this.images,
    required this.tags,
    required this.programm,
  });

  /// First MAIN image, or the first available image, or null.
  ImageRef? get mainImage {
    if (images.isEmpty) return null;
    return images.firstWhere(
      (img) => img.type == ImageType.main,
      orElse: () => images.first,
    );
  }

  factory Attraction.fromJson(Map<String, dynamic> json) => Attraction(
        externalId: json['externalId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        website: json['website'] as String?,
        instagram: json['instagram'] as String?,
        facebook: json['facebook'] as String?,
        youtube: json['youtube'] as String?,
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList(),
        programm: (json['programm'] as List<dynamic>? ?? [])
            .map((e) => ProgrammEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
