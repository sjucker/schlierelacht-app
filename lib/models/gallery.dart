/// Mirrors the backend `GalleryCategoryDTO` (with its `GalleryImageDTO`s
/// flattened to their Cloudflare ids). The backend returns categories in the
/// admin-defined order, with images newest-first within each.
class GalleryCategory {
  final String category;
  final List<String> imageIds;

  const GalleryCategory({required this.category, required this.imageIds});

  factory GalleryCategory.fromJson(Map<String, dynamic> json) => GalleryCategory(
    category: json['category'] as String,
    imageIds: (json['images'] as List<dynamic>? ?? []).map((e) => (e as Map<String, dynamic>)['cloudflareId'] as String).toList(),
  );
}
