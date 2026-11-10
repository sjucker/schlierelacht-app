import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../api/location_api.dart';
import '../config.dart';
import '../models/location.dart' as model;
import '../services/geolocation.dart';
import '../utils/external_links.dart';
import '../utils/location_labels.dart';
import '../widgets/async_view.dart';
import 'location_detail_screen.dart';

/// The Festplan (website: `festplan.vue`): every location flagged
/// `showInFestplan` as a colour-coded, labelled circle on the Schlierelacht
/// map style, with a colour legend on top. Tapping a circle opens a bottom
/// sheet with the location's type, distance (if the user's position is known),
/// an "open in maps" action and a link to the location detail.
class FestplanScreen extends StatefulWidget {
  const FestplanScreen({super.key});

  @override
  State<FestplanScreen> createState() => _FestplanScreenState();
}

class _FestplanScreenState extends State<FestplanScreen> {
  final _api = LocationApi();
  late Future<List<model.Location>> _future;

  final Map<String, model.Location> _byAnnotationId = {};
  geo.Position? _position;
  StreamSubscription<geo.Position>? _positionUpdates;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    // Kept current while the screen is open; read when a location sheet
    // opens. No setState: rebuilding would reset the map camera.
    _positionUpdates = GeolocationService.instance.watchPosition().listen((p) => _position = p);
  }

  // Only locations flagged for the festplan are placed on the map; the shared
  // /api/v1/location endpoint still returns every location (see Locations).
  Future<List<model.Location>> _fetch() async => (await _api.fetchLocations()).where((l) => l.showInFestplan).toList();

  @override
  void dispose() {
    _positionUpdates?.cancel();
    super.dispose();
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  Future<void> _onMapCreated(MapboxMap map, List<model.Location> locations) async {
    // Show the user's position dot when location permission is granted.
    try {
      await map.location.updateSettings(LocationComponentSettings(enabled: true, pulsingEnabled: true));
    } catch (_) {}

    final circles = await map.annotations.createCircleAnnotationManager();
    final labels = await map.annotations.createPointAnnotationManager();
    for (final loc in locations) {
      final point = Point(coordinates: Position(loc.longitude, loc.latitude));
      final annotation = await circles.create(
        CircleAnnotationOptions(
          geometry: point,
          circleRadius: 14,
          circleColor: locationTypeColor(loc.type),
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 2,
        ),
      );
      _byAnnotationId[annotation.id] = loc;
      await labels.create(
        PointAnnotationOptions(
          geometry: point,
          textField: loc.name,
          textOffset: [0, 1.8],
          textAnchor: TextAnchor.TOP,
          textSize: 12,
          textColor: 0xFF1F2937,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 1.5,
        ),
      );
    }
    circles.tapEvents(
      onTap: (annotation) {
        final loc = _byAnnotationId[annotation.id];
        if (loc != null) _showLocationSheet(loc);
      },
    );
  }

  void _showLocationSheet(model.Location loc) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final pos = _position;
        final distance = pos == null ? null : GeolocationService.instance.distanceMeters(pos.latitude, pos.longitude, loc.latitude, loc.longitude);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(locationTypeIcon(loc.type), color: Color(locationTypeColor(loc.type))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(loc.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(locationTypeLabel(loc.type), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                if (distance != null) ...[const SizedBox(height: 4), Text('${formatDistance(distance)} entfernt', style: theme.textTheme.bodyMedium)],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => openUrl(loc.googleMapsUrl),
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Google Maps öffnen'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocationDetailScreen(externalId: loc.externalId)));
                      },
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Centre of all placed locations (as the website does), or the festival
  /// centre when there are none.
  static Point _center(List<model.Location> locations) {
    if (locations.isEmpty) {
      return Point(coordinates: Position(festLongitude, festLatitude));
    }
    final lng = locations.fold<double>(0, (s, l) => s + l.longitude) / locations.length;
    final lat = locations.fold<double>(0, (s, l) => s + l.latitude) / locations.length;
    return Point(coordinates: Position(lng, lat));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Festplan')),
      body: mapboxAccessToken.isEmpty
          ? const _MissingToken()
          : AsyncView<List<model.Location>>(
              future: _future,
              onRetry: _reload,
              onData: (context, locations) => Column(
                children: [
                  const _Legend(),
                  Expanded(
                    child: MapWidget(
                      key: const ValueKey('festplan-map'),
                      styleUri: festMapStyleUri,
                      viewport: CameraViewportState(center: _center(locations), zoom: 16),
                      onMapCreated: (map) => _onMapCreated(map, locations),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Colour legend for the location types (website: the dots above the map).
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final types = model.LocationType.values.where((t) => t != model.LocationType.unknown);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          for (final type in types)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: Color(locationTypeColor(type)), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(locationTypeLabel(type), style: style),
              ],
            ),
        ],
      ),
    );
  }
}

class _MissingToken extends StatelessWidget {
  const _MissingToken();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Festplan nicht verfügbar.\n\nDie App wurde ohne Mapbox-Token gebaut. '
          'Starte sie mit --dart-define=MAPBOX_ACCESS_TOKEN=pk...',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
