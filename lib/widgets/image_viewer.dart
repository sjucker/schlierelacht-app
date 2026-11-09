import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config.dart';

/// Opens a fullscreen, swipeable, pinch-zoomable viewer over the given
/// Cloudflare image ids — the app's take on the website's gallery lightbox.
void showImageViewer(
  BuildContext context,
  List<String> cloudflareIds, {
  int initialIndex = 0,
}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) =>
        _ImageViewer(ids: cloudflareIds, initialIndex: initialIndex),
  ));
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.ids, required this.initialIndex});

  final List<String> ids;
  final int initialIndex;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.ids.length > 1
            ? Text('${_index + 1} / ${widget.ids.length}')
            : null,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Schliessen',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.ids.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: cloudflareImageUrl(widget.ids[i]),
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
