import 'package:flutter/material.dart';

import '../api/gallery_api.dart';
import '../models/gallery.dart';
import '../utils/external_links.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';
import '../widgets/image_viewer.dart';

/// The festival video the website embeds at the top of its gallery page.
const _festVideoUrl = 'https://www.facebook.com/schlierelacht/videos/3538727499751138/';

/// Photo galleries by category (website: `galerien.vue`). Tapping an image
/// opens a fullscreen viewer that swipes through its category.
class GalerieScreen extends StatefulWidget {
  const GalerieScreen({super.key});

  @override
  State<GalerieScreen> createState() => _GalerieScreenState();
}

class _GalerieScreenState extends State<GalerieScreen> {
  final _api = GalleryApi();
  late Future<List<GalleryCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchGallery();
  }

  void _reload() => setState(() => _future = _api.fetchGallery());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Galerie')),
      body: AsyncView<List<GalleryCategory>>(
        future: _future,
        onRetry: _reload,
        onData: (context, categories) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: Icon(Icons.play_circle_outline, size: 36, color: theme.colorScheme.primary),
                    title: const Text('Video ansehen'),
                    subtitle: const Text('Schlierefäscht auf Facebook'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => openUrl(_festVideoUrl),
                  ),
                ),
              ),
              if (categories.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(24), child: Text('Noch keine Bilder vorhanden.')),
                ),
              for (final category in categories) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      category.category.toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
                    itemCount: category.imageIds.length,
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: () => showImageViewer(context, category.imageIds, initialIndex: i),
                        child: CloudflareImage(cloudflareId: category.imageIds[i]),
                      ),
                    ),
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
