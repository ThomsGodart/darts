import '../session/session.dart';

/// The rules of a game played with [config], one statement per entry:
/// short sentences a first-time player can follow, with an example where
/// the scoring is not obvious.
List<String> gameRules(GameConfig config) => switch (config) {
  final X01Config config => [
    'Chaque joueur part de ${config.startScore} points. À son tour, il lance '
        '3 fléchettes et on retire leur total de son score.',
    'Le premier qui arrive exactement à 0 gagne.',
    ...switch (config.outRule) {
      OutRule.straight => [
        'On peut finir avec n’importe quelle fléchette.',
        'Si un tour fait descendre en dessous de 0, il est annulé : le '
            'joueur garde le score qu’il avait avant ce tour.',
      ],
      OutRule.double => [
        'Pour finir, la dernière fléchette doit être un double (l’anneau '
            'extérieur de la cible). Le plein centre compte comme un double.',
        'Exemple : il reste 40, il faut un double 20.',
        'Un tour est annulé s’il fait descendre en dessous de 0, s’il '
            'laisse exactement 1 point, ou s’il arrive à 0 sans finir sur un '
            'double. Le joueur garde alors le score qu’il avait avant ce tour.',
      ],
      OutRule.master => [
        'Pour finir, la dernière fléchette doit être un double ou un triple. '
            'Le plein centre compte comme un double.',
        'Exemple : il reste 57, un triple 19 finit la partie.',
        'Un tour est annulé s’il fait descendre en dessous de 0, s’il '
            'laisse exactement 1 point, ou s’il arrive à 0 sur un simple. Le '
            'joueur garde alors le score qu’il avait avant ce tour.',
      ],
    },
    if (config.doubleIn)
      'Double-in : les fléchettes d’un joueur ne comptent pas tant qu’il '
          'n’a pas touché un double.',
    if (config.legsToWin > 1)
      config.setsToWin > 1
          ? 'Match : le premier à ${config.legsToWin} manches gagne le set, '
                'le premier à ${config.setsToWin} sets gagne le match.'
          : 'Match : le premier à ${config.legsToWin} manches gagne.',
    if (config.isMatch) 'Le joueur qui commence change à chaque manche.',
  ],
  CricketConfig(:final variant) => [
    'On ne joue que sur 7 numéros : 20, 19, 18, 17, 16, 15 et le centre de '
        'la cible (bull).',
    'Une fléchette dans un de ces numéros lui donne des marques : 1 pour un '
        'simple, 2 pour un double, 3 pour un triple. Au centre : 1 pour '
        'l’anneau, 2 pour le plein centre.',
    'Un numéro est fermé quand un joueur y a 3 marques.',
    ...switch (variant) {
      CricketVariant.standard => [
        'Quand vous avez fermé un numéro, chaque marque en plus dessus vous '
            'rapporte sa valeur en points (25 pour le centre), tant qu’au '
            'moins un adversaire ne l’a pas fermé.',
        'Exemple : vous avez fermé le 20, pas votre adversaire. Un triple 20 '
            'vous rapporte 60 points.',
        'Un numéro fermé par tout le monde ne rapporte plus rien.',
        'Pour gagner, il faut avoir fermé les 7 numéros et avoir au moins '
            'autant de points que chaque adversaire. Si vous avez tout fermé '
            'en étant derrière aux points, il faut continuer à marquer.',
      ],
      CricketVariant.cutThroat => [
        'Quand vous avez fermé un numéro, chaque marque en plus dessus donne '
            'sa valeur en points (25 pour le centre) à chaque adversaire qui '
            'ne l’a pas fermé. Les points sont une pénalité.',
        'Exemple : vous avez fermé le 20, pas votre adversaire. Un triple 20 '
            'lui donne 60 points.',
        'Un numéro fermé par tout le monde ne donne plus rien.',
        'Pour gagner, il faut avoir fermé les 7 numéros et avoir au plus '
            'autant de points que chaque adversaire. Si vous avez tout fermé '
            'en ayant plus de points qu’un autre, il faut continuer à lui en '
            'donner.',
      ],
    },
  ],
  ShanghaiConfig(:final length, :final instantShanghai) => [
    'La partie se joue en ${length.numbers.length} manches, une par numéro, '
        'du ${length.numbers.first} au ${length.numbers.last} dans l’ordre.',
    'À chaque manche, chacun lance 3 fléchettes. Seules celles dans le '
        'numéro de la manche comptent : un simple vaut le numéro, un double '
        '2 fois le numéro, un triple 3 fois.',
    'Exemple : à la manche du 5, un simple vaut 5 points, un double 10, un '
        'triple 15. Une fléchette ailleurs vaut 0.',
    if (instantShanghai)
      'Shanghai : un joueur qui met un simple, un double et un triple du '
          'numéro dans le même tour gagne la partie immédiatement.',
    'Après la dernière manche, le plus de points gagne.',
  ],
  KillerConfig(:final lives, :final doublesToKiller) => [
    'Il faut au moins $minKillerPlayers joueurs. Chacun choisit un numéro de '
        '1 à 20 et part avec $lives vies.',
    'Seuls les doubles comptent : l’anneau extérieur de la cible.',
    doublesToKiller == 1
        ? 'Pour devenir Killer, il faut toucher le double de son propre '
              'numéro.'
        : 'Pour devenir Killer, il faut toucher $doublesToKiller fois le '
              'double de son propre numéro.',
    'Un Killer enlève une vie à un adversaire chaque fois qu’il touche le '
        'double du numéro de cet adversaire.',
    'Tant qu’on n’est pas Killer, on ne peut enlever de vie à personne.',
    'Attention : un Killer qui touche le double de son propre numéro perd '
        'lui-même une vie.',
    'À 0 vie, un joueur est éliminé. Le dernier en vie gagne.',
  ],
  HalveItConfig() => [
    'Tout le monde part de $halveItStartScore.',
    'Il y a ${halveItTargets.length} manches, chacune avec sa cible, dans cet '
        'ordre : 20, 16, double 7, 14, triple 10, 17, puis le centre.',
    'À chaque manche, chacun lance 3 fléchettes sur la cible. Chaque '
        'fléchette dedans ajoute sa valeur au score.',
    'Sur 20, 16, 14 et 17, tout le numéro compte : un double 20 vaut 40. '
        'Sur « double 7 », seul le double compte (14 points) ; sur '
        '« triple 10 », seul le triple (30 points). Au centre : 25 pour '
        'l’anneau, 50 pour le plein centre.',
    'Si aucune des 3 fléchettes ne touche la cible, le score du joueur est '
        'divisé par 2, arrondi au-dessus : 45 devient 23.',
    'Après le centre, le plus de points gagne.',
  ],
  GolfConfig(:final holes) => [
    'On joue $holes trous. Le trou 1 se joue sur le numéro 1, le trou 2 sur '
        'le 2, et ainsi de suite.',
    'À chaque trou, un joueur a jusqu’à 3 fléchettes. Il peut s’arrêter '
        'après n’importe laquelle : seule la dernière lancée compte, même si '
        'elle est moins bonne que les précédentes.',
    'La dernière fléchette donne le nombre de coups : dans le double du '
        'numéro, 1 coup ; dans le triple, 3 coups ; dans un simple, 4 coups ; '
        'à côté du numéro, $golfMissStrokes coups.',
    'Après le dernier trou, le moins de coups gagne.',
  ],
  AroundTheClockConfig(:final finishOnBull) => [
    'Il faut toucher les numéros 1, 2, 3… jusqu’à 20, dans l’ordre'
        '${finishOnBull ? ', puis le centre de la cible' : ''}.',
    'On vise le même numéro tant qu’on ne l’a pas touché. Simple, double ou '
        'triple, peu importe : une fléchette dedans valide le numéro.',
    'Dès qu’un numéro est touché, on vise le suivant, même au milieu de son '
        'tour de 3 fléchettes.',
    'Le premier arrivé au bout gagne tout de suite.',
  ],
  Bobs27Config() => [
    'Tout le monde part de $bobs27StartScore points.',
    'Il y a ${bobs27Targets.length} manches : double 1, double 2… jusqu’au '
        'double 20, puis le plein centre. À chaque manche, chacun lance 3 '
        'fléchettes sur le double de la manche.',
    'Chaque fléchette dans le double ajoute sa valeur. Exemple au double 6 : '
        'une fléchette dedans donne 12 points, deux en donnent 24.',
    'Si aucune des 3 fléchettes n’est dedans, on retire la valeur du double '
        'une seule fois : 12 points en moins au double 6.',
    'Au plein centre, chaque fléchette dedans donne 50 points ; aucune, 50 '
        'points en moins.',
    'Un joueur qui tombe à 0 ou moins est éliminé.',
    'Après le centre, le plus haut score gagne. Si tout le monde est '
        'éliminé avant, le dernier éliminé gagne.',
  ],
  CountUpConfig(:final rounds) => [
    'Tout le monde part de 0.',
    'On joue $rounds manches. À chaque manche, chacun lance 3 fléchettes et '
        'ajoute leur total à son score.',
    'Chaque fléchette vaut ce qu’elle touche : un triple 20 vaut 60, '
        'l’anneau du centre 25, le plein centre 50.',
    'Après la dernière manche, le plus gros total gagne.',
  ],
  BaseballConfig() => [
    'On joue $baseballInnings manches. La manche 1 se joue sur le numéro 1, '
        'la manche 2 sur le 2, et ainsi de suite.',
    'À chaque manche, chacun lance 3 fléchettes. Dans le numéro de la '
        'manche, un simple donne 1 point (un « run »), un double 2, un '
        'triple 3. Une fléchette ailleurs ne donne rien.',
    'Après la manche $baseballInnings, le plus de runs gagne.',
    'S’il y a égalité en tête, on joue une manche de plus sur le numéro '
        'suivant (10, puis 11…) jusqu’à ce que quelqu’un soit devant, au '
        'plus tard au $baseballLastInning.',
  ],
};
