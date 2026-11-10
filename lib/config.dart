/// App-wide configuration.
///
/// The API base URL mirrors the website's behaviour: an override can be passed
/// at build/run time, otherwise it falls back to the deployed production API.
/// Override with: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
/// (use http://10.0.2.2:8080 on the Android emulator to reach the host machine).
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://schlierelacht-api.ch');

/// Cloudflare image delivery base (same account id the website uses).
const String _cloudflareBaseUrl = 'https://imagedelivery.net/08WjJu0y_NwzY_GFS74XCw';

/// Builds the delivery URL for a Cloudflare image id.
///
/// Without a size it is the `public` variant (the stored image, capped at about
/// 1200 × 768). With [width] and/or [height] — in physical pixels — it is a
/// flexible variant (enabled for the account) at quality 80: with [cover] the
/// image fills both dimensions and is cropped, otherwise `scale-down` fits it
/// inside them without ever enlarging it.
String cloudflareImageUrl(String cloudflareId, {int? width, int? height, bool cover = false}) {
  if (width == null && height == null) return '$_cloudflareBaseUrl/$cloudflareId/public';
  final options = [if (width != null) 'w=$width', if (height != null) 'h=$height', 'fit=${cover ? 'cover' : 'scale-down'}', 'quality=80'];
  return '$_cloudflareBaseUrl/$cloudflareId/${options.join(',')}';
}

/// Widest box (physical px) that gets a flexible variant. Wider ones — the
/// full-width detail images on a phone — ask for about what `public` already
/// is, and re-encoding them made 13 of the 56 act photos bigger (measured
/// November 2026), so they keep `public`.
const int cloudflareFlexibleMaxWidth = 800;

/// Rounds a [logical] size up to physical pixels in steps of 100 (max 2000),
/// so boxes of similar size request — and cache — the same image.
int cloudflareSize(double logical, double devicePixelRatio) => (((logical * devicePixelRatio) / 100).ceil() * 100).clamp(100, 2000);

/// Asks Cloudflare for WebP (about 20 % smaller than JPEG). Without it the
/// delivery falls back to JPEG; AVIF must not be accepted, Flutter can't
/// decode it.
const Map<String, String> cloudflareImageHeaders = {'Accept': 'image/webp,image/*;q=0.8'};

/// Public Mapbox access token (`pk.*`) used by the map screen. Supplied at
/// build/run time so the secret stays out of source control:
/// `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk...`
/// (same token as the website's `MAPBOX_API_TOKEN`). Empty when unset — the
/// map screen then shows a hint instead of a broken map.
const String mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

/// Festival centre used as the map's initial camera target (Schlieren, ZH).
const double festLatitude = 47.3967;
const double festLongitude = 8.4475;

/// The custom Schlierelacht Mapbox style the website's maps use. Needs a
/// token from the same Mapbox account (the website's `MAPBOX_API_TOKEN`).
const String festMapStyleUri = 'mapbox://styles/schlierelacht/cmr9dkfx0003701r07otc18ui';

/// Festival start — the landing-page countdown runs until this moment
/// (same target as the website's home page).
final DateTime festStart = DateTime(2027, 9, 3, 17);

/// Official social-media profiles (website footer).
const String facebookUrl = 'https://www.facebook.com/schlierelacht/';
const String instagramUrl = 'https://www.instagram.com/schlierelacht/';
const String linkedinUrl = 'https://www.linkedin.com/company/schlierelacht/';

/// The website's privacy policy. The app has no in-app copy and opens this in
/// the browser — app stores require a privacy policy reachable from the app.
const String datenschutzUrl = '$websiteUrl/datenschutz/';

/// The public website. Shared links point here, and the app claims the paths it
/// can show itself (see `utils/deep_links.dart`), so they open in the app.
const String websiteUrl = 'https://schlierelacht.ch';

/// Hashtag the Social Media screen asks visitors to post with.
const String instagramHashtag = '#schlierelacht';
