/// Mirrors the backend `LocationType` enum.
enum LocationType { stage, foodStand, bar, tent, attraction, sanitary, info, eventLocation, unknown }

LocationType _locationTypeFromJson(String? value) {
  switch (value) {
    case 'STAGE':
      return LocationType.stage;
    case 'FOOD_STAND':
      return LocationType.foodStand;
    case 'BAR':
      return LocationType.bar;
    case 'TENT':
      return LocationType.tent;
    case 'ATTRACTION':
      return LocationType.attraction;
    case 'SANITARY':
      return LocationType.sanitary;
    case 'INFO':
      return LocationType.info;
    case 'EVENT_LOCATION':
      return LocationType.eventLocation;
    default:
      return LocationType.unknown;
  }
}

/// Mirrors the backend `LocationDTO`.
class Location {
  final String externalId;
  final LocationType type;
  final String name;
  final double latitude;
  final double longitude;
  final String googleMapsUrl;
  final String? cloudflareId;
  final String? mapId;

  /// Whether the location is placed on the Festplan map. The location list
  /// still shows every location.
  final bool showInFestplan;

  const Location({
    required this.externalId,
    required this.type,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.googleMapsUrl,
    this.cloudflareId,
    this.mapId,
    this.showInFestplan = false,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    externalId: json['externalId'] as String,
    type: _locationTypeFromJson(json['type'] as String?),
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    googleMapsUrl: json['googleMapsUrl'] as String,
    cloudflareId: json['cloudflareId'] as String?,
    mapId: json['mapId'] as String?,
    showInFestplan: json['showInFestplan'] as bool? ?? false,
  );
}
