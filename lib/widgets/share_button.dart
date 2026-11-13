import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../config.dart';

/// App-bar action that shares a page of the website via the system share
/// sheet: the title, then `websiteUrl` + [path] on a new line. The link opens in the app for anyone
/// who has it installed (see `utils/deep_links.dart`), in the browser otherwise.
///
/// [title] is the screen's data future; while it is still loading (or if it
/// failed) only the link is shared.
class ShareButton extends StatelessWidget {
  const ShareButton({super.key, required this.path, this.title});

  /// Website path, e.g. `/programm/A12`.
  final String path;
  final Future<String>? title;

  Future<void> _share(BuildContext context) async {
    final url = '$websiteUrl$path';
    // iPad shows the sheet as a popover anchored at the button.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    String? name;
    try {
      name = await title;
    } catch (_) {}
    await SharePlus.instance.share(ShareParams(text: name == null ? url : '$name\n$url', subject: name, sharePositionOrigin: origin));
  }

  @override
  Widget build(BuildContext context) {
    // Callers pass a derived future (`_future.then((x) => x.name)`) that only
    // _share listens to. Without this, a failed load would surface as an
    // unhandled error; _share still sees and catches it.
    title?.ignore();
    return IconButton(tooltip: 'Teilen', icon: Icon(Icons.adaptive.share), onPressed: () => _share(context));
  }
}
