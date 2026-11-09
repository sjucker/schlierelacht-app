/// Mirrors the backend `MeetupJahrgang` enum. [label] carries the age group and
/// its meetup slot, exactly as the website shows it
/// (`app/utils/meetup-jahrgang.ts`).
enum MeetupJahrgang {
  before1954('BEFORE_1954', '1953 + älter – Mo, 6.9.2027, 17:30'),
  born1954To1958('BORN_1954_1958', '1954–1958 – Di, 7.9.2027, 17:30'),
  born1959To1963('BORN_1959_1963', '1959–1963 – Mo, 6.9.2027, 17:30'),
  born1964To1968('BORN_1964_1968', '1964–1968 – Di, 7.9.2027, 17:30'),
  born1969To1973('BORN_1969_1973', '1969–1973 – Mi, 8.9.2027, 17:30'),
  born1974To1978('BORN_1974_1978', '1974–1978 – Do, 9.9.2027, 17:30'),
  born1979To1983('BORN_1979_1983', '1979–1983 – Mi, 8.9.2027, 17:30'),
  born1984To1988('BORN_1984_1988', '1984–1988 – Do, 9.9.2027, 17:30'),
  born1989To1993('BORN_1989_1993', '1989–1993 – Fr, 10.9.2027, 17:30'),
  born1994To1998('BORN_1994_1998', '1994–1998 – Fr, 10.9.2027, 17:30'),
  after1998('AFTER_1998', '1999 + jünger – Fr, 10.9.2027, 17:30');

  const MeetupJahrgang(this.wire, this.label);

  final String wire;
  final String label;

  /// Null for a value this build does not know yet (a newer backend).
  static MeetupJahrgang? fromWire(String? value) {
    for (final j in values) {
      if (j.wire == value) return j;
    }
    return null;
  }
}

/// Mirrors the backend `MeetupEntryDTO` — a public participant-list entry.
class MeetupEntry {
  final String firstname;
  final String lastname;
  final MeetupJahrgang? jahrgang;

  const MeetupEntry({required this.firstname, required this.lastname, required this.jahrgang});

  factory MeetupEntry.fromJson(Map<String, dynamic> json) =>
      MeetupEntry(firstname: json['firstname'] as String, lastname: json['lastname'] as String, jahrgang: MeetupJahrgang.fromWire(json['jahrgang'] as String?));
}

/// Mirrors the backend `MeetupRegistrationDTO` (POST body).
class MeetupRegistration {
  final String firstname;
  final String lastname;
  final String email;
  final MeetupJahrgang jahrgang;
  final bool showOnList;

  const MeetupRegistration({required this.firstname, required this.lastname, required this.email, required this.jahrgang, required this.showOnList});

  Map<String, dynamic> toJson() => {'firstname': firstname, 'lastname': lastname, 'email': email, 'jahrgang': jahrgang.wire, 'showOnList': showOnList};
}
