/// Mirrors the backend `SponsoringType` enum, in display order, with German
/// section labels.
enum SponsoringType {
  hauptsponsoren('HAUPTSPONSOREN', 'Hauptsponsoren'),
  organisation('ORGANISATION', 'Organisation'),
  gastregion('GASTREGION', 'Gastregion'),
  gold('GOLD', 'Gold'),
  silber('SILBER', 'Silber'),
  bronze('BRONZE', 'Bronze'),
  goenner('GOENNER', 'Gönner'),
  partner('PARTNER', 'Partner'),
  unknown('', 'Weitere');

  const SponsoringType(this.wire, this.label);

  final String wire;
  final String label;

  static SponsoringType fromWire(String? value) => values.firstWhere(
        (t) => t.wire == value,
        orElse: () => SponsoringType.unknown,
      );
}

/// Mirrors the backend `SponsoringDTO`.
class Sponsoring {
  final SponsoringType type;
  final String name;
  final String? cloudflareId;
  final String? url;

  const Sponsoring({
    required this.type,
    required this.name,
    this.cloudflareId,
    this.url,
  });

  factory Sponsoring.fromJson(Map<String, dynamic> json) => Sponsoring(
        type: SponsoringType.fromWire(json['type'] as String?),
        name: json['name'] as String,
        cloudflareId: json['cloudflareId'] as String?,
        url: json['url'] as String?,
      );
}
