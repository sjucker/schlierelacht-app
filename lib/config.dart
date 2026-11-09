/// App-wide configuration.
///
/// The API base URL mirrors the website's behaviour: an override can be passed
/// at build/run time, otherwise it falls back to the deployed production API.
/// Override with: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
/// (use http://10.0.2.2:8080 on the Android emulator to reach the host machine).
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://schlierelacht-api.ch');

/// Cloudflare image delivery base (same account id the website uses).
const String _cloudflareBaseUrl = 'https://imagedelivery.net/08WjJu0y_NwzY_GFS74XCw';

/// Builds the public delivery URL for a Cloudflare image id.
String cloudflareImageUrl(String cloudflareId) => '$_cloudflareBaseUrl/$cloudflareId/public';

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
