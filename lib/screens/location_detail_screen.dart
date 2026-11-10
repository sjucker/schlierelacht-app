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
import '../widgets/cloudflare_image.dart';
import '../widgets/share_button.dart';

/// Detail of one festival location (website: `locations/[id].vue`): its image,
/// a map centred on it, and a Google Maps button. Adds the distance from the
/// user's position when known.
class LocationDetailScreen extends StatefulWidget {
  const LocationDetailScreen({super.key, required this.externalId});

  final String externalId;

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final _api = LocationApi();
  late Future<model.Location> _future;

  /// Updated as the user moves; only the distance label listens, so the map
  /// is never rebuilt (which could reset its camera).
  final _position = ValueNotifier<geo.Position?>(null);
  StreamSubscription<geo.Position>? _positionUpdates;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchLocation(widget.externalId);
    // Distances follow the user while the screen is open.
    _positionUpdates = GeolocationService.instance.watchPosition().listen((p) => _position.value = p);
  }

  @override
  void dispose() {
    _positionUpdates?.cancel();
    _position.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _future = _api.fetchLocation(widget.externalId);
  });

  Future<void> _onMapCreated(MapboxMap map, model.Location loc) async {
    try {
      await map.location.updateSettings(LocationComponentSettings(enabled: true, pulsingEnabled: true));
    } catch (_) {}
    final circles = await map.annotations.createCircleAnnotationManager();
    await circles.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(loc.longitude, loc.latitude)),
        circleRadius: 14,
        circleColor: 0xFFFF0000,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        actions: [ShareButton(path: '/locations/${widget.externalId}', title: _future.then((l) => l.name))],
      ),
      body: AsyncView<model.Location>(
        future: _future,
        onRetry: _reload,
        onData: (context, loc) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (loc.cloudflareId != null) SizedBox(height: 250, child: CloudflareImage(cloudflareId: loc.cloudflareId)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(locationTypeIcon(loc.type), color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.name,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ValueListenableBuilder<geo.Position?>(
                      valueListenable: _position,
                      builder: (context, pos, _) {
                        final distance = pos == null
                            ? null
                            : GeolocationService.instance.distanceMeters(pos.latitude, pos.longitude, loc.latitude, loc.longitude);
                        return Text(
                          distance == null ? locationTypeLabel(loc.type) : '${locationTypeLabel(loc.type)} · ${formatDistance(distance)} entfernt',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: () => openUrl(loc.googleMapsUrl), icon: const Icon(Icons.map_outlined), label: const Text('Google Maps')),
                  ],
                ),
              ),
              if (mapboxAccessToken.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 350,
                      child: MapWidget(
                        key: ValueKey('location-map-${loc.externalId}'),
                        styleUri: festMapStyleUri,
                        viewport: CameraViewportState(center: Point(coordinates: Position(loc.longitude, loc.latitude)), zoom: 18),
                        onMapCreated: (map) => _onMapCreated(map, loc),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
