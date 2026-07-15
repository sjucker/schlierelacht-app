/// Mirrors the backend `AttractionType` enum. The wire value is the enum name
/// (e.g. `FOOD`), used as the `?type=` query parameter on `/api/attraction`.
enum AttractionType {
  artist('ARTIST'),
  food('FOOD'),
  exhibition('EXHIBITION'),
  discussion('DISCUSSION'),
  event('EVENT'),
  ride('RIDE');

  const AttractionType(this.wire);

  final String wire;
}
