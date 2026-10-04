import 'package:flutter/material.dart';

import '../session/session.dart';
import 'score_list.dart';

/// The hole being played and everyone's strokes in a Golf game.
class GolfBoard extends StatelessWidget {
  const GolfBoard({super.key, required this.game});

  final GolfGame game;

  @override
  Widget build(BuildContext context) => ScoreList(
    key: const Key('golf-board'),
    title: 'Trou ${game.currentHole} / ${game.config.holes}',
    hint: game.dartsInVisit.isEmpty
        ? 'La dernière fléchette compte : D 1 · T 2 · S 3 · raté 5'
        : 'S’arrêter maintenant : ${strokesLabel(game.strokesIfStopped)}',
    lines: [
      for (final (i, score) in game.scores.indexed)
        (
          name: score.player.name,
          value: '${score.strokes}',
          isActive: i == game.activeIndex && !game.isFinished,
        ),
    ],
  );
}

/// "1 coup", "3 coups".
String strokesLabel(int strokes) => strokes == 1 ? '1 coup' : '$strokes coups';
