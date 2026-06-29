/// App-wide configuration.
///
/// The API base URL mirrors the website's behaviour: an override can be passed
/// at build/run time, otherwise it falls back to the deployed production API.
/// Override with: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
/// (use http://10.0.2.2:8080 on the Android emulator to reach the host machine).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://schlierelacht-api.ch',
);

/// Cloudflare image delivery base (same account id the website uses).
const String _cloudflareBaseUrl =
    'https://imagedelivery.net/08WjJu0y_NwzY_GFS74XCw';

/// Builds the public delivery URL for a Cloudflare image id.
String cloudflareImageUrl(String cloudflareId) =>
    '$_cloudflareBaseUrl/$cloudflareId/public';
