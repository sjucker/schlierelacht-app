import 'package:material_ui/material_ui.dart';

import '../models/location.dart';

/// German display label for a [LocationType] (matches the website's Festplan
/// legend and the backend enum descriptions).
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
    case LocationType.eventLocation:
      return 'Anlass-Ort';
    case LocationType.unknown:
      return 'Ort';
  }
}

/// Marker colour (ARGB) for a [LocationType] — the same palette as the
/// website's Festplan (`festplan.vue` → `TYPE_COLORS`).
int locationTypeColor(LocationType type) {
  switch (type) {
    case LocationType.stage:
      return 0xFF2B3585;
    case LocationType.foodStand:
      return 0xFFF97316;
    case LocationType.bar:
      return 0xFFDC2626;
    case LocationType.tent:
      return 0xFF16A34A;
    case LocationType.attraction:
      return 0xFF9333EA;
    case LocationType.sanitary:
      return 0xFF86EDD1;
    case LocationType.info:
      return 0xFFE19D6C;
    case LocationType.eventLocation:
      return 0xFF0891B2;
    case LocationType.unknown:
      return 0xFF6B7280;
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
    case LocationType.eventLocation:
      return Icons.business_center_outlined;
    case LocationType.unknown:
      return Icons.place;
  }
}
