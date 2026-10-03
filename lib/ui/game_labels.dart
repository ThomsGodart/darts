import '../session/session.dart';

/// "Cricket" or "Cut-Throat", as the setup, the board and the history say.
String variantLabel(CricketVariant variant) => switch (variant) {
  CricketVariant.standard => 'Cricket',
  CricketVariant.cutThroat => 'Cut-Throat',
};

/// "501 Double-out", "301 Straight-out", "Cricket", "Shanghai 1–7", …
String configLabel(GameConfig config) => switch (config) {
  X01Config(:final startScore, :final outRule) =>
    '$startScore ${outRule == OutRule.double ? 'Double-out' : 'Straight-out'}',
  CricketConfig(:final variant) => variantLabel(variant),
  ShanghaiConfig(:final length, :final instantShanghai) => [
    'Shanghai ${switch (length) {
      ShanghaiLength.oneToSeven => '1–7',
      ShanghaiLength.fourteenToTwenty => '14–20',
      ShanghaiLength.oneToTwenty => '1–20',
    }}',
    if (!instantShanghai) 'sans instant',
  ].join(' · '),
  KillerConfig(:final lives, :final doublesToKiller) =>
    'Killer ${lives}v'
        '${doublesToKiller == 1 ? '' : ' · ${doublesToKiller}D'}',
};
