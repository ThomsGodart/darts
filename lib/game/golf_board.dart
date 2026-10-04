import 'package:flutter/material.dart';

import '../session/session.dart';
import 'input_pane.dart';
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

/// Single, double and treble of the hole's number, and a miss. Ending the
/// visit keeps the last dart thrown.
class GolfInput extends StatelessWidget {
  const GolfInput({
    super.key,
    required this.hole,
    required this.dartsInVisit,
    required this.onDart,
    required this.onEndVisit,
    this.onUndo,
  });

  final int hole;
  final List<Dart> dartsInVisit;
  final ValueChanged<Dart> onDart;
  final VoidCallback onEndVisit;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) => InputPane(
    dartsInVisit: dartsInVisit,
    onUndo: onUndo,
    onEndVisit: onEndVisit,
    children: [
      Row(
        children: [
          PadKey(label: 'S$hole', onTap: () => onDart(Dart.single(hole))),
          PadKey(label: 'D$hole', onTap: () => onDart(Dart.double(hole))),
          PadKey(label: 'T$hole', onTap: () => onDart(Dart.treble(hole))),
        ],
      ),
      Row(
        children: [PadKey(label: 'Raté', onTap: () => onDart(Dart.miss))],
      ),
    ],
  );
}
