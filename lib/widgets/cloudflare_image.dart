import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config.dart';

/// Displays a Cloudflare-delivered image from its id, with a neutral
/// placeholder while loading and a fallback icon when there is no image.
class CloudflareImage extends StatelessWidget {
  const CloudflareImage({
    super.key,
    required this.cloudflareId,
    this.fit = BoxFit.cover,
  });

  final String? cloudflareId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final id = cloudflareId;
    if (id == null || id.isEmpty) {
      return _Placeholder(child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outlineVariant,
      ));
    }
    return CachedNetworkImage(
      imageUrl: cloudflareImageUrl(id),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const _Placeholder(),
      errorWidget: (context, url, error) => _Placeholder(child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outlineVariant,
      )),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: child,
    );
  }
}
