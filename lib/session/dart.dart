/// Where one dart landed.
class Dart {
  const Dart._(this.sector, this.multiplier);

  const Dart.single(int sector) : this._(sector, 1);
  const Dart.double(int sector) : this._(sector, 2);
  const Dart.treble(int sector) : this._(sector, 3);

  /// Rebuilds a dart from its stored fields.
  const Dart.fromStored({required int sector, required int multiplier})
    : this._(sector, multiplier);

  static const outerBull = Dart._(bullSector, 1);
  static const bull = Dart._(bullSector, 2);
  static const miss = Dart._(0, 0);

  static const bullSector = 25;

  /// 1–20, [bullSector], or 0 for a miss.
  final int sector;

  /// 1 single, 2 double (the bull is the double of 25), 3 treble; 0 miss.
  final int multiplier;

  int get score => sector * multiplier;

  /// The cricket number this dart marks and how many marks, or null when
  /// it lands outside 15–20 and the bull.
  ({int number, int marks})? get cricketMarks =>
      sector == Dart.bullSector || (sector >= 15 && sector <= 20)
      ? (number: sector, marks: multiplier)
      : null;

  bool get isDouble => multiplier == 2;

  /// Whether a real board has this spot (there is no treble bull).
  bool get isValid =>
      this == miss ||
      (sector >= 1 && sector <= 20 && multiplier >= 1 && multiplier <= 3) ||
      (sector == bullSector && (multiplier == 1 || multiplier == 2));

  /// Usual scorer notation: T20, D16, 5, 25, Bull, or 0 for a miss.
  String get notation => switch ((sector, multiplier)) {
    (0, _) => '0',
    (bullSector, 1) => '25',
    (bullSector, 2) => 'Bull',
    (_, 2) => 'D$sector',
    (_, 3) => 'T$sector',
    _ => '$sector',
  };

  @override
  bool operator ==(Object other) =>
      other is Dart && other.sector == sector && other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(sector, multiplier);

  @override
  String toString() => notation;
}
