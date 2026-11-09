import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Thin wrapper around `geolocator` for requesting location permission and
/// reading the current position. Every method fails soft (returns null / false)
/// so callers never have to handle location exceptions — the UI simply omits
/// distance information when the position is unavailable.
class GeolocationService {
  GeolocationService._();

  static final GeolocationService instance = GeolocationService._();

  Completer<Position?>? _inFlight;

  /// Requests location permission (used by onboarding). Returns true when
  /// granted (while-in-use or always).
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  /// Returns the current device position, or null if location is unavailable
  /// (service off, permission denied, or any error). Concurrent calls share a
  /// single in-flight request.
  Future<Position?> currentPosition() {
    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<Position?>();
    _inFlight = completer;
    _resolve().then((pos) {
      _inFlight = null;
      completer.complete(pos);
    });
    return completer.future;
  }

  Future<Position?> _resolve() async {
    try {
      if (!await ensurePermission()) return null;
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  /// Great-circle distance in metres between two points.
  double distanceMeters(double lat1, double lon1, double lat2, double lon2) => Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
}

/// Formats a metre distance the way the reference app does: "<100 m",
/// "circa 450 m", "circa 2.3 km", ">10 km".
String formatDistance(double meters) {
  if (meters < 100) return '< 100 m';
  if (meters < 1000) return 'circa ${(meters / 50).round() * 50} m';
  if (meters <= 10000) return 'circa ${(meters / 1000).toStringAsFixed(1)} km';
  return '> 10 km';
}
