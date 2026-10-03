import '../session/session.dart';

/// "Cricket" or "Cut-Throat", as the setup, the board and the history say.
String variantLabel(CricketVariant variant) => switch (variant) {
  CricketVariant.standard => 'Cricket',
  CricketVariant.cutThroat => 'Cut-Throat',
};

/// "501 DO", "301 SO", "Cricket", "Cut-Throat".
String configLabel(GameConfig config) => switch (config) {
  X01Config(:final startScore, :final outRule) =>
    '$startScore ${outRule == OutRule.double ? 'DO' : 'SO'}',
  CricketConfig(:final variant) => variantLabel(variant),
};
