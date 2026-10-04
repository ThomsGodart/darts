import 'package:flutter/material.dart';

import '../session/session.dart';
import 'input_pane.dart';
import 'score_list.dart';

/// "7", or "Bull" for the bull's sector.
String _numberLabel(int sector) =>
    sector == Dart.bullSector ? 'Bull' : '$sector';

/// Each player's next number in an Around the Clock game.
class AroundTheClockBoard extends StatelessWidget {
  const AroundTheClockBoard({super.key, required this.game});

  final AroundTheClockGame game;

  @override
  Widget build(BuildContext context) => ScoreList(
    key: const Key('around-the-clock-board'),
    title: game.isFinished
        ? 'Tour bouclé'
        : 'Cible ${_numberLabel(game.activeTarget)}',
    hint: 'Dans l’ordre, n’importe quel anneau compte',
    lines: [
      for (final (i, score) in game.scores.indexed)
        (
          name: score.player.name,
          value: '${score.hits} / ${game.config.targets}',
          isActive: i == game.activeIndex && !game.isFinished,
        ),
    ],
  );
}

/// The one key of Around the Clock: the active player's number.
List<DartKey> aroundTheClockKeys(AroundTheClockGame game) => [
  (
    _numberLabel(game.activeTarget),
    game.activeTarget == Dart.bullSector
        ? Dart.outerBull
        : Dart.single(game.activeTarget),
  ),
];

/// The one key of Bob's 27: the double of the round.
List<DartKey> bobs27Keys(Bobs27Game game) => [
  (game.currentTarget.notation, game.currentTarget),
];

/// The double of the round and everyone's score in a Bob's 27 game.
class Bobs27Board extends StatelessWidget {
  const Bobs27Board({super.key, required this.game});

  final Bobs27Game game;

  @override
  Widget build(BuildContext context) {
    final target = game.currentTarget;
    return ScoreList(
      key: const Key('bobs-27-board'),
      title: 'Cible ${target.notation}',
      hint:
          'Chaque touche : +${target.score} · '
          'aucune touche : −${target.score}',
      lines: [
        for (final (i, score) in game.scores.indexed)
          (
            name: score.player.name,
            value: score.isOut ? 'OUT  ${score.points}' : '${score.points}',
            isActive: i == game.activeIndex && !game.isFinished,
          ),
      ],
    );
  }
}

/// The round and everyone's total in a Count-Up game.
class CountUpBoard extends StatelessWidget {
  const CountUpBoard({super.key, required this.game});

  final CountUpGame game;

  @override
  Widget build(BuildContext context) => ScoreList(
    key: const Key('count-up-board'),
    title: 'Manche ${game.round} / ${game.config.rounds}',
    lines: [
      for (final (i, score) in game.scores.indexed)
        if (i == game.activeIndex && !game.isFinished)
          (
            name: score.player.name,
            value: '${game.activeLivePoints}',
            isActive: true,
          )
        else
          (name: score.player.name, value: '${score.points}', isActive: false),
    ],
  );
}

/// The inning and everyone's runs in a Baseball game.
class BaseballBoard extends StatelessWidget {
  const BaseballBoard({super.key, required this.game});

  final BaseballGame game;

  @override
  Widget build(BuildContext context) => ScoreList(
    key: const Key('baseball-board'),
    title: game.inning > baseballInnings
        ? 'Manche ${game.inning} · prolongation'
        : 'Manche ${game.inning} / $baseballInnings',
    hint: 'Sur le ${game.inning} : simple 1 · double 2 · triple 3',
    lines: [
      // Runs are counted dart by dart: the score is already up to date.
      for (final (i, score) in game.scores.indexed)
        (
          name: score.player.name,
          value: '${score.runs}',
          isActive: i == game.activeIndex && !game.isFinished,
        ),
    ],
  );
}
