import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in an external application (browser, maps app, …). Returns false
/// if the URL is empty or cannot be launched; callers can ignore the result.
Future<bool> openUrl(String? url) async {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
