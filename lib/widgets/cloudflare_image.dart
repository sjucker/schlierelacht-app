import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config.dart';

/// Displays a Cloudflare-delivered image from its id, with a neutral
/// placeholder while loading and a fallback icon when there is no image.
///
/// By default the image fills its (bounded) parent. With [natural] it instead
/// takes the full available width at its own aspect ratio, never cropped —
/// how the website shows detail images.
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
    if (natural) {
      return CachedNetworkImage(
        imageUrl: cloudflareImageUrl(id),
        fit: BoxFit.fitWidth,
        width: double.infinity,
        placeholder: (context, url) => const SizedBox(height: 200, child: _Placeholder()),
        errorWidget: (context, url, error) => fallback(200),
      );
    }
    return CachedNetworkImage(
      imageUrl: cloudflareImageUrl(id),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const _Placeholder(),
      errorWidget: (context, url, error) => fallback(null),
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
