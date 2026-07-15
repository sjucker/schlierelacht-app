import 'package:flutter/material.dart';

import '../models/location.dart';

/// German display label for a [LocationType] (matches the backend enum
/// descriptions).
String locationTypeLabel(LocationType type) {
  switch (type) {
    case LocationType.stage:
      return 'Bühne';
    case LocationType.foodStand:
      return 'Essensstand';
    case LocationType.bar:
      return 'Bar';
    case LocationType.tent:
      return 'Festzelt';
    case LocationType.attraction:
      return 'Attraktion';
    case LocationType.sanitary:
      return 'Sanitäre Anlagen';
    case LocationType.info:
      return 'Info-Stand';
    case LocationType.unknown:
      return 'Ort';
  }
}

/// Icon used for a location in lists and the map bottom sheet.
IconData locationTypeIcon(LocationType type) {
  switch (type) {
    case LocationType.stage:
      return Icons.music_note;
    case LocationType.foodStand:
      return Icons.restaurant;
    case LocationType.bar:
      return Icons.local_bar;
    case LocationType.tent:
      return Icons.festival;
    case LocationType.attraction:
      return Icons.attractions;
    case LocationType.sanitary:
      return Icons.wc;
    case LocationType.info:
      return Icons.info_outline;
    case LocationType.unknown:
      return Icons.place;
  }
}
