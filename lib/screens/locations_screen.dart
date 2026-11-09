import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../api/location_api.dart';
import '../models/location.dart';
import '../services/geolocation.dart';
import '../utils/external_links.dart';
import '../utils/location_labels.dart';
import '../widgets/async_view.dart';
import 'location_detail_screen.dart';

/// All festival locations with a name search (website: `locations/index.vue`).
/// Adds each location's distance when the user's position is known and a
/// one-tap directions button. Tapping a row opens the location detail.
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _api = LocationApi();
  late Future<List<Location>> _future;
  Position? _position;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchLocations();
    GeolocationService.instance.currentPosition().then((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  void _reload() => setState(() => _future = _api.fetchLocations());

  String? _distanceLabel(Location loc) {
    final pos = _position;
    if (pos == null) return null;
    final meters = GeolocationService.instance.distanceMeters(
        pos.latitude, pos.longitude, loc.latitude, loc.longitude);
    return formatDistance(meters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: AsyncView<List<Location>>(
        future: _future,
        onRetry: _reload,
        onData: (context, all) {
          final q = _query.trim().toLowerCase();
          final locations = q.isEmpty
              ? all
              : all.where((l) => l.name.toLowerCase().contains(q)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SearchBar(
                  hintText: 'Ort suchen…',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: locations.isEmpty
                    ? const Center(child: Text('Keine Orte gefunden.'))
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          itemCount: locations.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final loc = locations[i];
                            final distance = _distanceLabel(loc);
                            return ListTile(
                              leading: Icon(locationTypeIcon(loc.type),
                                  color: Theme.of(context).colorScheme.primary),
                              title: Text(loc.name),
                              subtitle: Text(
                                distance == null
                                    ? locationTypeLabel(loc.type)
                                    : '${locationTypeLabel(loc.type)} · $distance',
                              ),
                              trailing: IconButton(
                                tooltip: 'In Karten öffnen',
                                icon: const Icon(Icons.directions_outlined),
                                onPressed: () => openUrl(loc.googleMapsUrl),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LocationDetailScreen(
                                      externalId: loc.externalId),
                                ),
                              ),
                            );
                          },
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
