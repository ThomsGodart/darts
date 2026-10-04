import '../session/session.dart';

/// The rules of a game played with [config], one statement per entry,
/// as the players need them spelled out before starting.
List<String> gameRules(GameConfig config) => switch (config) {
  final X01Config config => [
    'Chaque joueur part de ${config.startScore} et retire le total de chaque '
        'volée de 3 fléchettes.',
    'Le premier à arriver exactement à 0 gagne.',
    switch (config.outRule) {
      OutRule.straight => 'N’importe quelle fléchette peut finir.',
      OutRule.double =>
        'La dernière fléchette doit être un double ; le bull compte comme '
            'un double.',
      OutRule.master =>
        'La dernière fléchette doit être un double ou un triple.',
    },
    if (config.outRule == OutRule.straight)
      'Bust : une volée qui ferait passer sous 0 ne compte pas.'
    else
      'Bust : une volée qui ferait passer sous 0, laisserait 1, ou finirait '
          'sur une mauvaise fléchette ne compte pas.',
    if (config.doubleIn)
      'Double-in : rien ne compte avant le premier double du joueur.',
    if (config.legsToWin > 1)
      config.setsToWin > 1
          ? 'Match : le premier à ${config.legsToWin} manches gagne le set, '
                'le premier à ${config.setsToWin} sets gagne le match.'
          : 'Match : le premier à ${config.legsToWin} manches gagne.',
    if (config.isMatch) 'Le joueur qui commence change à chaque manche.',
  ],
  CricketConfig(:final variant) => [
    'Les numéros en jeu sont 20, 19, 18, 17, 16, 15 et le bull.',
    'Un simple vaut 1 marque, un double 2, un triple 3 ; le bull extérieur 1, '
        'le bull 2.',
    'Trois marques ferment un numéro.',
    switch (variant) {
      CricketVariant.standard =>
        'Sur un numéro qu’il a fermé, chaque marque en plus rapporte au '
            'joueur la valeur du numéro, tant qu’un adversaire ne l’a pas '
            'fermé.',
      CricketVariant.cutThroat =>
        'Sur un numéro qu’il a fermé, chaque marque en plus donne la valeur '
            'du numéro aux adversaires qui ne l’ont pas fermé.',
    },
    'Un numéro fermé par tout le monde ne rapporte plus rien.',
    switch (variant) {
      CricketVariant.standard =>
        'Gagne le premier qui a tout fermé avec le plus de points, ou autant '
            'que le meilleur.',
      CricketVariant.cutThroat =>
        'Gagne le premier qui a tout fermé avec le moins de points, ou '
            'autant que le meilleur.',
    },
  ],
  ShanghaiConfig(:final length, :final instantShanghai) => [
    'Chaque manche se joue sur un numéro, de ${length.numbers.first} à '
        '${length.numbers.last} : tout le monde lance 3 fléchettes dessus.',
    'Seules les fléchettes dans le numéro comptent : simple × 1, double × 2, '
        'triple × 3.',
    if (instantShanghai)
      'Shanghai : un simple, un double et un triple du numéro dans la même '
          'volée gagnent la partie immédiatement.',
    'Après le dernier numéro, le plus de points gagne.',
  ],
  KillerConfig(:final lives, :final doublesToKiller) => [
    'Il faut au moins $minKillerPlayers joueurs. Chacun choisit un numéro et '
        'part avec $lives vies.',
    doublesToKiller == 1
        ? 'Toucher le double de son numéro fait d’un joueur un Killer.'
        : 'Toucher $doublesToKiller fois le double de son numéro fait d’un '
              'joueur un Killer.',
    'Un Killer retire une vie à un adversaire à chaque double touché sur le '
        'numéro de celui-ci.',
    'Un Killer qui touche le double de son propre numéro perd une vie.',
    'Un joueur sans vie est éliminé ; le dernier en vie gagne.',
  ],
  HalveItConfig() => [
    'Tout le monde part de $halveItStartScore points.',
    'Les cibles se jouent dans l’ordre : '
        '${halveItTargets.map((t) => t.label).join(', ')}. Tout le monde '
        'lance 3 fléchettes sur chacune.',
    'Les fléchettes dans la cible s’ajoutent au score. Sur D7 et T10, seul '
        'cet anneau compte ; sur le bull, 25 et 50 comptent.',
    'Une volée sans aucune touche divise le score par 2, arrondi au '
        'supérieur.',
    'Après le bull, le plus de points gagne.',
  ],
  GolfConfig(:final holes) => [
    'On joue $holes trous : le trou n se joue sur le numéro n.',
    'Chaque joueur a jusqu’à 3 fléchettes et peut s’arrêter quand il veut : '
        'c’est la dernière lancée qui compte.',
    'Un double vaut 1 coup, un triple 2, un simple 3 ; tout le reste '
        '$golfMissStrokes.',
    'Après le dernier trou, le moins de coups gagne.',
  ],
  AroundTheClockConfig(:final finishOnBull) => [
    'Il faut toucher les numéros de 1 à 20 dans l’ordre'
        '${finishOnBull ? ', puis le bull' : ''}.',
    'N’importe quel anneau du numéro compte, et on passe aussitôt au '
        'suivant : plusieurs numéros peuvent tomber dans une volée.',
    'Le premier arrivé au bout gagne immédiatement.',
  ],
  Bobs27Config() => [
    'Tout le monde part de $bobs27StartScore points.',
    'Chacun lance 3 fléchettes sur chaque double, de D1 à D20, puis sur le '
        'bull.',
    'Chaque touche ajoute la valeur du double (D6 = 12, bull = 50).',
    'Une volée sans aucune touche retire cette valeur une fois.',
    'À zéro ou moins, le joueur est éliminé.',
    'Après le bull, le plus haut score gagne ; si tout le monde est éliminé, '
        'le dernier à tomber gagne.',
  ],
  CountUpConfig(:final rounds) => [
    'On joue $rounds manches de 3 fléchettes.',
    'Chaque fléchette compte sa valeur.',
    'Après la dernière manche, le plus gros total gagne.',
  ],
  BaseballConfig() => [
    'On joue $baseballInnings manches : la manche n se joue sur le numéro n.',
    'Un simple vaut 1 run, un double 2, un triple 3 ; le reste ne vaut rien.',
    'Après $baseballInnings manches, le plus de runs gagne.',
    'En cas d’égalité en tête, on joue des prolongations sur les numéros '
        'suivants, jusqu’au $baseballLastInning.',
  ],
};
