/// Mirrors the backend `OkTeam` enum, in the website's display order, with
/// German labels.
enum OkTeam {
  praesidiales('PRAESIDIALES_STADT_KOMMUNIKATION_FINANZEN',
      'Präsidiales/Stadt/Kommunikation/Finanzen'),
  bauInfrastruktur('BAU_INFRASTRUKTUR', 'Bau/Infrastruktur'),
  gastronomie('GASTRONOMIE', 'Gastronomie'),
  programmAktivitaeten('PROGRAMM_AKTIVITAETEN', 'Programm/Aktivitäten'),
  sicherheit('SICHERHEIT', 'Sicherheit'),
  sponsoring('SPONSORING', 'Sponsoring');

  const OkTeam(this.wire, this.label);

  final String wire;
  final String label;

  /// Null for a team this build does not know yet (a newer backend).
  static OkTeam? fromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// Mirrors the backend `OkMemberDTO` — a member of the organizing committee.
class OkMember {
  final String name;
  final String role;
  final String? email;
  final String? cloudflareId;

  const OkMember({
    required this.name,
    required this.role,
    this.email,
    this.cloudflareId,
  });

  factory OkMember.fromJson(Map<String, dynamic> json) => OkMember(
        name: json['name'] as String,
        role: json['role'] as String,
        email: json['email'] as String?,
        cloudflareId: json['cloudflareId'] as String?,
      );
}

/// Mirrors the backend `OkTeamMemberDTO`.
class OkTeamMember {
  final String name;
  final OkTeam? team;
  final String? email;

  const OkTeamMember({required this.name, required this.team, this.email});

  factory OkTeamMember.fromJson(Map<String, dynamic> json) => OkTeamMember(
        name: json['name'] as String,
        team: OkTeam.fromWire(json['team'] as String?),
        email: json['email'] as String?,
      );
}

/// Mirrors the backend `OkDTO`.
class Ok {
  final List<OkMember> members;
  final List<OkTeamMember> teamMembers;

  const Ok({required this.members, required this.teamMembers});

  factory Ok.fromJson(Map<String, dynamic> json) => Ok(
        members: (json['members'] as List<dynamic>? ?? [])
            .map((e) => OkMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        teamMembers: (json['teamMembers'] as List<dynamic>? ?? [])
            .map((e) => OkTeamMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
