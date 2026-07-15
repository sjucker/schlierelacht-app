import 'image_ref.dart';
import 'programm_entry.dart';

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

  /// Operator ("Betreiber"). Only set for FOOD attractions; null otherwise.
  final String? operator;
  final List<ImageRef> images;
  final List<ProgrammEntry> programm;

  const Attraction({
    required this.externalId,
    required this.name,
    required this.description,
    this.website,
    this.instagram,
    this.facebook,
    this.youtube,
    this.operator,
    required this.images,
    required this.programm,
  });

  /// The single MAIN image, or null when the attraction has none.
  /// An attraction has at most one main image (guaranteed by the backend);
  /// additional images are never promoted to main.
  ImageRef? get mainImage {
    for (final img in images) {
      if (img.type == ImageType.main) return img;
    }
    return null;
  }

  /// All ADDITIONAL (gallery) images, in order. May be empty.
  List<ImageRef> get additionalImages =>
      images.where((img) => img.type == ImageType.additional).toList();

  factory Attraction.fromJson(Map<String, dynamic> json) => Attraction(
        externalId: json['externalId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        website: json['website'] as String?,
        instagram: json['instagram'] as String?,
        facebook: json['facebook'] as String?,
        youtube: json['youtube'] as String?,
        operator: json['operator'] as String?,
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        programm: (json['programm'] as List<dynamic>? ?? [])
            .map((e) => ProgrammEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
