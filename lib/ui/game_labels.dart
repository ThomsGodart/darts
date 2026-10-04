import '../session/session.dart';

/// "Cricket" or "Cut-Throat", as the setup, the board and the history say.
String variantLabel(CricketVariant variant) => switch (variant) {
  CricketVariant.standard => 'Cricket',
  CricketVariant.cutThroat => 'Cut-Throat',
};

/// "501 Double-out", "301 Straight-out · 1er à 3", "Cricket", …
String configLabel(GameConfig config) => switch (config) {
  final X01Config config => [
    '${config.startScore} '
        '${config.doubleIn ? 'Double-in ' : ''}'
        '${outRuleLabel(config.outRule)}',
    if (config.legsToWin > 1) '1er à ${config.legsToWin}',
    if (config.setsToWin > 1) '${config.setsToWin} sets',
  ].join(' · '),
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
  HalveItConfig() => 'Halve-It',
  GolfConfig(:final holes) => 'Golf $holes trous',
  AroundTheClockConfig(:final finishOnBull) =>
    'Tour de l’horloge${finishOnBull ? ' · bull' : ''}',
  Bobs27Config() => 'Bob’s 27',
  CountUpConfig(:final rounds) => 'Count-Up $rounds manches',
  BaseballConfig() => 'Baseball',
};

/// "X01", "Cricket", …: the game as the setup offers it.
String kindLabel(GameKind kind) => switch (kind) {
  GameKind.x01 => 'X01',
  GameKind.cricket => 'Cricket',
  GameKind.shanghai => 'Shanghai',
  GameKind.killer => 'Killer',
  GameKind.halveIt => 'Halve-It',
  GameKind.golf => 'Golf',
  GameKind.aroundTheClock => 'Tour de l’horloge',
  GameKind.bobs27 => 'Bob’s 27',
  GameKind.countUp => 'Count-Up',
  GameKind.baseball => 'Baseball',
};

/// "Ana 2 · Bob 1": the legs each of [players] won in the match; with
/// sets, "Ana 1 (2) · Bob 0 (1)": sets, then the legs of the set.
String matchScoreLabel(MatchScore match, List<Player> players) => [
  for (final player in players)
    match.config.setsToWin > 1
        ? '${player.name} ${match.setsOf(player)} (${match.legsOf(player)})'
        : '${player.name} ${match.legsOf(player)}',
].join(' · ');

/// "Manches" or, with sets, "Sets (manches)": what a match score counts.
String matchScoreHeading(MatchScore match) =>
    match.config.setsToWin > 1 ? 'Sets (manches)' : 'Manches';

/// "Double-out", "Master-out", "Straight-out".
String outRuleLabel(OutRule rule) => switch (rule) {
  OutRule.straight => 'Straight-out',
  OutRule.double => 'Double-out',
  OutRule.master => 'Master-out',
};
