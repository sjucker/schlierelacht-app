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

/// Interactive festival map. Fetches all locations and drops a colour-coded
/// circle for each; tapping one opens a bottom sheet with its name, type,
/// distance (if the user's position is known) and an "open in maps" action.
class KarteScreen extends StatefulWidget {
  const KarteScreen({super.key});

  @override
  State<KarteScreen> createState() => _KarteScreenState();
}

class _KarteScreenState extends State<KarteScreen> {
  final _api = LocationApi();
  late Future<List<model.Location>> _future;

  final Map<String, model.Location> _byAnnotationId = {};
  geo.Position? _position;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchLocations();
    GeolocationService.instance.currentPosition().then((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  void _reload() => setState(() => _future = _api.fetchLocations());

  Future<void> _onMapCreated(MapboxMap map, List<model.Location> locations) async {
    // Show the user's position dot when location permission is granted.
    try {
      await map.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    } catch (_) {}

    final circles = await map.annotations.createCircleAnnotationManager();
    for (final loc in locations) {
      final annotation = await circles.create(CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(loc.longitude, loc.latitude),
        ),
        circleRadius: 8,
        circleColor: _colorFor(loc.type),
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ));
      _byAnnotationId[annotation.id] = loc;
    }
    circles.tapEvents(onTap: (annotation) {
      final loc = _byAnnotationId[annotation.id];
      if (loc != null) _showLocationSheet(loc);
    });
  }

  void _showLocationSheet(model.Location loc) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final pos = _position;
        final distance = pos == null
            ? null
            : GeolocationService.instance.distanceMeters(
                pos.latitude, pos.longitude, loc.latitude, loc.longitude);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(locationTypeIcon(loc.type),
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(loc.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(locationTypeLabel(loc.type),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
                if (distance != null) ...[
                  const SizedBox(height: 4),
                  Text('${formatDistance(distance)} entfernt',
                      style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => openUrl(loc.googleMapsUrl),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('In Karten öffnen'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karte')),
      body: mapboxAccessToken.isEmpty
          ? const _MissingToken()
          : AsyncView<List<model.Location>>(
              future: _future,
              onRetry: _reload,
              onData: (context, locations) => MapWidget(
                key: const ValueKey('karte-map'),
                styleUri: MapboxStyles.OUTDOORS,
                viewport: CameraViewportState(
                  center: Point(
                    coordinates: Position(festLongitude, festLatitude),
                  ),
                  zoom: 15,
                ),
                onMapCreated: (map) => _onMapCreated(map, locations),
              ),
            ),
    );
  }

  static int _colorFor(model.LocationType type) {
    switch (type) {
      case model.LocationType.stage:
        return 0xFF2B3585; // fest-blue
      case model.LocationType.foodStand:
        return 0xFFE07A1F; // orange
      case model.LocationType.bar:
        return 0xFF8E24AA; // purple
      case model.LocationType.tent:
        return 0xFF2E7D32; // green
      case model.LocationType.attraction:
        return 0xFFD81B60; // pink
      case model.LocationType.sanitary:
        return 0xFF0097A7; // teal
      case model.LocationType.info:
        return 0xFF616161; // grey
      case model.LocationType.unknown:
        return 0xFF2B3585;
    }
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
          'Karte nicht verfügbar.\n\nDie App wurde ohne Mapbox-Token gebaut. '
          'Starte sie mit --dart-define=MAPBOX_ACCESS_TOKEN=pk...',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
