import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../config.dart';

/// Displays a Cloudflare-delivered image from its id, with a neutral
/// placeholder while loading and a fallback icon when there is no image.
///
/// By default the image fills its (bounded) parent. With [natural] it instead
/// takes the full available width at its own aspect ratio, never cropped —
/// how the website shows detail images.
///
/// Small boxes (up to [cloudflareFlexibleMaxWidth] physical px wide) request
/// only the size they are shown at (see [cloudflareImageUrl]), rounded up to
/// 100 px: a 96 px Gastro thumbnail loads about 20 KB instead of the 120 KB
/// photo. Wider or unbounded boxes, such as full-width detail images, use the
/// `public` variant. Every request asks for WebP.
class CloudflareImage extends StatelessWidget {
  const CloudflareImage({super.key, required this.cloudflareId, this.fit = BoxFit.cover, this.natural = false});

  final String? cloudflareId;
  final BoxFit fit;
  final bool natural;

  @override
  Widget build(BuildContext context) {
    final id = cloudflareId;
    if (id == null || id.isEmpty) {
      return _Placeholder(child: Icon(Icons.image_outlined, size: 48, color: Theme.of(context).colorScheme.outlineVariant));
    }
    Widget fallback(double? height) => SizedBox(
      height: height,
      child: _Placeholder(child: Icon(Icons.broken_image_outlined, size: 48, color: Theme.of(context).colorScheme.outlineVariant)),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        int? size(double logical) => logical.isFinite && logical > 0 ? cloudflareSize(logical, dpr) : null;
        final width = size(constraints.maxWidth);
        // Only small boxes gain from a flexible variant; wide ones keep public.
        final flexible = width != null && width <= cloudflareFlexibleMaxWidth;
        if (natural) {
          return CachedNetworkImage(
            imageUrl: flexible ? cloudflareImageUrl(id, width: width) : cloudflareImageUrl(id),
            httpHeaders: cloudflareImageHeaders,
            fit: BoxFit.fitWidth,
            width: double.infinity,
            placeholder: (context, url) => const SizedBox(height: 200, child: _Placeholder()),
            errorWidget: (context, url, error) => fallback(200),
          );
        }
        return CachedNetworkImage(
          imageUrl: flexible ? cloudflareImageUrl(id, width: width, height: size(constraints.maxHeight), cover: fit == BoxFit.cover) : cloudflareImageUrl(id),
          httpHeaders: cloudflareImageHeaders,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => const _Placeholder(),
          errorWidget: (context, url, error) => fallback(null),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, alignment: Alignment.center, child: child);
  }
}
