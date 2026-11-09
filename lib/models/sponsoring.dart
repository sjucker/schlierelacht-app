/// Mirrors the backend `SponsoringType` enum, declared in the website's display
/// order (`sponsoren.vue` → `TYPE_ORDER`). [label] is only a fallback — the
/// section titles come from `GET /api/v1/sponsoring/type` (see
/// [SponsoringTypeInfo]).
enum SponsoringType {
  organisation('ORGANISATION', 'Organisation'),
  hauptsponsoren('HAUPTSPONSOREN', 'Hauptsponsoren'),
  partner('PARTNER', 'Partner'),
  gastregion('GASTREGION', 'Gastregion'),
  gold('GOLD', 'Gold'),
  silber('SILBER', 'Silber'),
  bronze('BRONZE', 'Bronze'),
  goenner('GOENNER', 'Gönner'),
  unknown('', 'Weitere');

  const SponsoringType(this.wire, this.label);

  final String wire;
  final String label;

  static SponsoringType fromWire(String? value) => values.firstWhere((t) => t.wire == value, orElse: () => SponsoringType.unknown);
}

/// Mirrors the backend `SponsoringTypeDTO` — a tier with its display title.
class SponsoringTypeInfo {
  final SponsoringType type;
  final String description;

  const SponsoringTypeInfo({required this.type, required this.description});

  factory SponsoringTypeInfo.fromJson(Map<String, dynamic> json) =>
      SponsoringTypeInfo(type: SponsoringType.fromWire(json['type'] as String?), description: json['description'] as String);
}

/// Mirrors the backend `SponsoringDTO`.
class Sponsoring {
  final SponsoringType type;
  final String name;
  final String? cloudflareId;
  final String? url;

  const Sponsoring({required this.type, required this.name, this.cloudflareId, this.url});

  factory Sponsoring.fromJson(Map<String, dynamic> json) => Sponsoring(
    type: SponsoringType.fromWire(json['type'] as String?),
    name: json['name'] as String,
    cloudflareId: json['cloudflareId'] as String?,
    url: json['url'] as String?,
  );
}
