import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/darts_space.dart';
import '../session/session.dart';
import '../session_controller.dart';
import '../session_launcher.dart';
import '../ui/average_label.dart';
import '../ui/game_labels.dart';
import '../ui/persist_failure_banner.dart';
import 'cricket_board.dart';
import 'game_shell.dart';
import 'killer_board.dart';
import 'scoreboard.dart';
import 'screen_awake.dart';
import 'shanghai_board.dart';
import 'turn_banner.dart';
import 'visit_input.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.launcher,
    this.onChangeSetup,
    this.screenAwake = const WakelockScreenAwake(),
  });

  final SessionController controller;

  /// When set, a storage failure banner is shown if writes stop.
  final SessionLauncher? launcher;

  /// Between games: lets players join, leave or reorder, or the rules
  /// change, then starts the next game. Null hides the option.
  final Future<void> Function()? onChangeSetup;
  final ScreenAwake screenAwake;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  SessionController get controller => widget.controller;

  /// What the listener last saw, to tell a new game, a visit or an undo.
  late int _gamesSeen;
  late int _visitsSeen;
  bool _screenKeptOn = false;

  /// Name shown by the turn banner; null when no banner shows.
  String? _bannerPlayerName;

  @override
  void initState() {
    super.initState();
    _gamesSeen = controller.state.games.length;
    _visitsSeen = controller.state.game!.visitsPlayed;
    controller.addListener(_onGameChanged);
    // Game screens may rotate; home/setup stay natural portrait when we leave.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _syncScreenAwake();
  }

  @override
  void dispose() {
    controller.removeListener(_onGameChanged);
    if (_screenKeptOn) widget.screenAwake.release();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _onGameChanged() {
    final state = controller.state;
    final game = state.game!;
    final isNewGame = state.games.length != _gamesSeen;
    if (isNewGame) {
      // A new game: nothing to announce yet.
      setState(() => _bannerPlayerName = null);
    } else if (game.visitsPlayed > _visitsSeen && !game.isFinished) {
      // Only a completed visit passes the phone on; an undo does not.
      HapticFeedback.mediumImpact();
      setState(() => _bannerPlayerName = game.activePlayer.name);
    } else if (game.visitsPlayed < _visitsSeen) {
      setState(() => _bannerPlayerName = null);
    }
    _gamesSeen = state.games.length;
    _visitsSeen = game.visitsPlayed;
    _syncScreenAwake();
  }

  void _syncScreenAwake() {
    final inProgress = !controller.state.game!.isFinished;
    if (inProgress == _screenKeptOn) return;
    _screenKeptOn = inProgress;
    inProgress ? widget.screenAwake.keepOn() : widget.screenAwake.release();
  }

  @override
  Widget build(BuildContext context) {
    final launcher = widget.launcher;
    final gameBody = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final game = controller.state.game!;
        final bannerPlayerName = _bannerPlayerName;
        final statePane = switch (game) {
          final X01Game game => Scoreboard(game: game),
          final CricketGame game => CricketBoard(
            game: game,
            onDart: game.isFinished || game.config.input != CricketInput.board
                ? null
                : controller.throwDart,
          ),
          final ShanghaiGame game => ShanghaiBoard(game: game),
          final KillerGame game => KillerBoard(game: game),
        };
        final inputPane = game.isFinished
            ? _GameOverPanel(
                session: controller.state,
                onRematch: controller.rematch,
                onUndo: controller.undo,
                onChangeSetup: widget.onChangeSetup,
                onEnd: () => _endSession(context),
              )
            : switch (game) {
                final KillerGame game
                    when game.phase == KillerPhase.assigning =>
                  KillerAssignInput(
                    key: ValueKey('assign-${game.activeIndex}'),
                    taken: game.takenNumbers,
                    onAssign: controller.assignNumber,
                    onUndo: controller.canUndo ? controller.undo : null,
                  ),
                final KillerGame game => KillerPlayInput(
                  key: ValueKey(game.visitsPlayed),
                  dartsInVisit: game.dartsInVisit,
                  onDart: controller.throwDart,
                  onEndVisit: controller.endVisit,
                  onUndo: controller.canUndo ? controller.undo : null,
                ),
                final ShanghaiGame game => ShanghaiInput(
                  key: ValueKey(game.visitsPlayed),
                  number: game.currentNumber,
                  dartsInVisit: game.dartsInVisit,
                  onDart: controller.throwDart,
                  onEndVisit: controller.endVisit,
                  onUndo: controller.canUndo ? controller.undo : null,
                ),
                final X01Game game => VisitInput(
                  key: ValueKey(game.visitsPlayed),
                  onSubmit: (score) => _submit(context, game, score),
                  onDart: controller.throwDart,
                  dartsInVisit: game.dartsInVisit,
                  onEndVisit: controller.endVisit,
                  onUndo: controller.canUndo ? controller.undo : null,
                ),
                final CricketGame game
                    when game.config.input == CricketInput.board =>
                  CricketBoardInput(
                    dartsInVisit: game.dartsInVisit,
                    onDart: controller.throwDart,
                    onEndVisit: controller.endVisit,
                    onUndo: controller.canUndo ? controller.undo : null,
                  ),
                CricketGame() => VisitInput(
                  key: ValueKey(game.visitsPlayed),
                  onSubmit: null,
                  onDart: controller.throwDart,
                  dartsInVisit: game.dartsInVisit,
                  onEndVisit: controller.endVisit,
                  onUndo: controller.canUndo ? controller.undo : null,
                ),
              };
        return Stack(
          children: [
            Column(
              children: [
                _GameBar(label: configLabel(game.config)),
                Expanded(
                  child: GameShell(statePane: statePane, inputPane: inputPane),
                ),
              ],
            ),
            if (bannerPlayerName != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TurnBanner(
                  key: ValueKey(game.visitsPlayed),
                  playerName: bannerPlayerName,
                  onDone: () => setState(() => _bannerPlayerName = null),
                ),
              ),
          ],
        );
      },
    );

    return Scaffold(
      body: SafeArea(
        child: launcher == null
            ? gameBody
            : ListenableBuilder(
                listenable: launcher,
                builder: (context, _) => Column(
                  children: [
                    if (launcher.persistFailure != null)
                      const PersistFailureBanner(),
                    Expanded(child: gameBody),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _endSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la session ?'),
        content: const Text('Elle passera dans l’historique.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    controller.endSession();
    Navigator.of(context).pop();
  }

  Future<void> _submit(BuildContext context, X01Game game, int score) async {
    int? dartsAtCheckout;
    final options = game.checkoutDartOptions(score);
    if (options.length == 1) {
      dartsAtCheckout = options.single;
    } else if (options.isNotEmpty) {
      dartsAtCheckout = await _askCheckoutDarts(context, options);
      if (dartsAtCheckout == null || !context.mounted) return;
    }
    final result = controller.submitVisitTotal(
      score,
      dartsAtCheckout: dartsAtCheckout,
    );
    if (result is Rejected && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Score invalide : $score')));
    }
  }
}

/// Slim bar over the game: the way back to the menu, and what is played.
/// Leaving keeps the session open, to resume from the home screen.
class _GameBar extends StatelessWidget {
  const _GameBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: const Key('leave-game'),
        tooltip: 'Retour au menu',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}

/// Asks how many darts the checkout took; null if dismissed.
Future<int?> _askCheckoutDarts(BuildContext context, List<int> options) {
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Combien de fléchettes ?'),
      actions: [
        for (final darts in options)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(darts),
            child: Text('$darts'),
          ),
      ],
    ),
  );
}

/// End of a game: the winner, everyone's averages, and what comes next.
class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.session,
    required this.onRematch,
    required this.onUndo,
    required this.onEnd,
    this.onChangeSetup,
  });

  final SessionState session;
  final VoidCallback onRematch;

  /// Reopens the game by taking back the checkout.
  final VoidCallback onUndo;
  final Future<void> Function()? onChangeSetup;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final game = session.game!;
    final stats = _statsOf(session, game);
    final onChangeSetup = this.onChangeSetup;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${game.winner!.name} gagne !',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: DartsSpace.sm),
            Table(
              key: const Key('game-averages'),
              columnWidths: const {0: FlexColumnWidth()},
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    for (final heading in stats.headings)
                      _Cell(heading, style: textTheme.labelMedium),
                  ],
                ),
                for (final (player, values) in stats.rows)
                  TableRow(
                    children: [
                      Text(player.name, style: textTheme.titleMedium),
                      for (final value in values) _Cell(value),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: DartsSpace.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onRematch,
                icon: const Icon(Icons.replay),
                label: Text('Rejouer', style: textTheme.titleLarge),
              ),
            ),
            const SizedBox(height: DartsSpace.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: DartsSpace.sm,
              children: [
                if (onChangeSetup != null)
                  TextButton.icon(
                    onPressed: onChangeSetup,
                    icon: const Icon(Icons.group),
                    label: const Text('Partie suivante'),
                  ),
                TextButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo),
                  label: Text(switch (game) {
                    X01Game() => 'Annuler le checkout',
                    CricketGame() ||
                    ShanghaiGame() ||
                    KillerGame() => 'Annuler la dernière fléchette',
                  }),
                ),
                TextButton.icon(
                  onPressed: onEnd,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Terminer la session'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The end-of-game table: column headings, then each player's values.
typedef _Stats = ({List<String> headings, List<(Player, List<String>)> rows});

_Stats _statsOf(SessionState session, Game game) {
  // From the second game on: each session stat of a game type played in it,
  // so a cricket game still shows the X01 average and the other way round.
  final later = session.games.length > 1;
  final sessionX01 = later && session.games.any((g) => g is X01Game);
  final sessionCricket = later && session.games.any((g) => g is CricketGame);
  List<String> sessionStats(Player player) => [
    if (sessionX01) averageLabel(session.averageOf(player)),
    if (sessionCricket) averageLabel(session.marksPerRoundOf(player)),
  ];
  final sessionHeadings = [
    if (sessionX01) 'moy. session',
    if (sessionCricket) 'MPR session',
  ];
  return switch (game) {
    X01Game(:final scores) => (
      headings: ['moy.', ...sessionHeadings],
      rows: [
        for (final score in scores)
          (
            score.player,
            [
              averageLabel(score.threeDartAverage),
              ...sessionStats(score.player),
            ],
          ),
      ],
    ),
    CricketGame(:final scores) => (
      headings: ['pts', 'MPR', ...sessionHeadings],
      rows: [
        for (final score in scores)
          (
            score.player,
            [
              '${score.points}',
              averageLabel(game.marksPerRound(score.player)),
              ...sessionStats(score.player),
            ],
          ),
      ],
    ),
    ShanghaiGame(:final scores) => (
      headings: ['pts', ...sessionHeadings],
      rows: [
        for (final score in scores)
          (score.player, ['${score.points}', ...sessionStats(score.player)]),
      ],
    ),
    KillerGame(:final scores) => (
      headings: ['vies', ...sessionHeadings],
      rows: [
        for (final score in scores)
          (
            score.player,
            [
              score.isOut ? 'OUT' : '${score.lives ?? 0}',
              ...sessionStats(score.player),
            ],
          ),
      ],
    ),
  };
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: DartsSpace.lg),
    child: Text(text, textAlign: TextAlign.end, style: style),
  );
}
