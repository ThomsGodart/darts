import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/darts_space.dart';
import '../theme/darts_tokens.dart';
import '../session/session.dart';
import '../session_controller.dart';
import '../session_launcher.dart';
import '../ui/game_labels.dart';
import '../ui/game_stats.dart';
import '../ui/persist_failure_banner.dart';
import '../ui/stats_table_view.dart';
import 'cricket_board.dart';
import 'game_shell.dart';
import 'golf_board.dart';
import 'halve_it_board.dart';
import 'input_pane.dart';
import 'killer_board.dart';
import 'round_boards.dart';
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
    this.onCancelGame,
    this.portraitLock = false,
    this.screenAwake = const WakelockScreenAwake(),
    this.botDelay = const Duration(milliseconds: 900),
    this.botRandom,
  });

  final SessionController controller;

  /// When set, a storage failure banner is shown if writes stop.
  final SessionLauncher? launcher;

  /// Between games: lets players join, leave or reorder, or the rules
  /// change, then starts the next game. Null hides the option.
  final Future<void> Function()? onChangeSetup;

  /// Back during a game: once the game is cancelled, reopens the setup
  /// on what it was started with, and says whether another game started.
  /// Null makes Back simply leave the screen.
  final Future<bool> Function(GameSetup cancelled)? onCancelGame;

  /// Whether the screen stays in portrait when the phone is turned; it
  /// follows the phone otherwise.
  final bool portraitLock;
  final ScreenAwake screenAwake;

  /// How long a virtual opponent takes to throw.
  final Duration botDelay;

  /// What a virtual opponent's visits are drawn from; a fresh one by
  /// default.
  final Random? botRandom;

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

  /// Set while Back is being handled: blocks a second one.
  bool _cancelling = false;

  /// Pending visit of a virtual opponent, if it is its turn.
  Timer? _botTimer;
  late final Random _botRandom = widget.botRandom ?? Random();

  @override
  void initState() {
    super.initState();
    _gamesSeen = controller.state.games.length;
    _visitsSeen = controller.state.game!.visitsPlayed;
    controller.addListener(_onGameChanged);
    // The game screen may rotate, unless the players locked it; home and
    // setup stay in portrait, and take it back when we leave.
    SystemChrome.setPreferredOrientations(
      widget.portraitLock
          ? const [DeviceOrientation.portraitUp]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );
    _syncScreenAwake();
    _scheduleBot();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    controller.removeListener(_onGameChanged);
    if (_screenKeptOn) widget.screenAwake.release();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _onGameChanged() {
    final state = controller.state;
    final game = state.game;
    if (game == null) {
      // The only game was cancelled: nothing to show until the next one.
      _botTimer?.cancel();
      _gamesSeen = 0;
      _visitsSeen = 0;
      _syncScreenAwake();
      setState(() => _bannerPlayerName = null);
      return;
    }
    final isNewGame = state.games.length != _gamesSeen;
    if (isNewGame) {
      // A new game: nothing to announce yet.
      setState(() => _bannerPlayerName = null);
    } else if (game.visitsPlayed > _visitsSeen && !game.isFinished) {
      // Only a completed visit passes the phone on; an undo does not.
      HapticFeedback.mediumImpact();
      // In a team, whoever of its members is up.
      setState(() => _bannerPlayerName = game.thrower.name);
    } else if (game.visitsPlayed < _visitsSeen) {
      setState(() => _bannerPlayerName = null);
    }
    _gamesSeen = state.games.length;
    _visitsSeen = game.visitsPlayed;
    _syncScreenAwake();
    _scheduleBot();
  }

  /// When a virtual opponent is up, has it throw after [GameScreen.botDelay].
  void _scheduleBot() {
    _botTimer?.cancel();
    final state = controller.state;
    final game = state.game;
    if (game == null ||
        game.isFinished ||
        state.isEnded ||
        !game.activePlayer.isBot) {
      return;
    }
    final games = state.games.length;
    final visits = game.visitsPlayed;
    _botTimer = Timer(widget.botDelay, () {
      final now = controller.state.game!;
      // Undone or replaced meanwhile: this visit is no longer due.
      if (!mounted ||
          controller.state.games.length != games ||
          now.visitsPlayed != visits ||
          now.isFinished) {
        return;
      }
      switch (now) {
        case X01Game():
          final visit = botVisit(now, _botRandom);
          controller.submitVisitTotal(
            visit.score,
            dartsAtCheckout: visit.dartsAtCheckout,
          );
        case CountUpGame():
          controller.submitVisitTotal(
            botCountUpVisit(now.activePlayer.botAverage!, _botRandom),
          );
        default:
          // The setup only lets a virtual opponent into these two games.
          break;
      }
    });
  }

  /// Takes the latest input back, and with it whatever a virtual opponent
  /// threw since: undoing must hand the phone back to a person.
  void _undo() {
    controller.undo();
    while (controller.canUndo &&
        !controller.state.game!.isFinished &&
        controller.state.game!.activePlayer.isBot) {
      controller.undo();
    }
  }

  void _syncScreenAwake() {
    final inProgress = !(controller.state.game?.isFinished ?? true);
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
        final game = controller.state.game;
        // Cancelled, the setup of the next one is open over this screen.
        if (game == null) return const SizedBox.shrink();
        final bannerPlayerName = _bannerPlayerName;
        final onUndo = controller.canUndo ? _undo : null;
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
          final HalveItGame game => HalveItBoard(game: game),
          final GolfGame game => GolfBoard(game: game),
          final AroundTheClockGame game => AroundTheClockBoard(game: game),
          final Bobs27Game game => Bobs27Board(game: game),
          final CountUpGame game => CountUpBoard(game: game),
          final BaseballGame game => BaseballBoard(game: game),
        };
        final inputPane = game.isFinished
            ? _GameOverPanel(
                session: controller.state,
                onRematch: controller.rematch,
                onUndo: _undo,
                onChangeSetup: widget.onChangeSetup,
                onEnd: () => _endSession(context),
              )
            : switch (game) {
                _ when game.activePlayer.isBot => InputPane(
                  onUndo: onUndo,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(DartsSpace.lg),
                      child: Text(
                        '${game.activePlayer.name} joue…',
                        key: const Key('bot-playing'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                final KillerGame game
                    when game.phase == KillerPhase.assigning =>
                  KillerAssignInput(
                    key: ValueKey('assign-${game.activeIndex}'),
                    taken: game.takenNumbers,
                    onAssign: controller.assignNumber,
                    onUndo: onUndo,
                  ),
                final KillerGame game => KillerPlayInput(
                  key: ValueKey(game.visitsPlayed),
                  dartsInVisit: game.dartsInVisit,
                  onDart: controller.throwDart,
                  onEndVisit: controller.endVisit,
                  onUndo: onUndo,
                ),
                final CountUpGame game => VisitInput(
                  key: ValueKey(game.visitsPlayed),
                  onSubmit: (score) => _submitTotal(context, score),
                  onDart: controller.throwDart,
                  dartsInVisit: game.dartsInVisit,
                  onEndVisit: controller.endVisit,
                  onUndo: onUndo,
                ),
                final HalveItGame game => _dartKeys(
                  game,
                  halveItKeys(game.currentTarget),
                ),
                final GolfGame game => _dartKeys(
                  game,
                  ringKeys(game.currentHole),
                ),
                final AroundTheClockGame game => _dartKeys(
                  game,
                  aroundTheClockKeys(game),
                ),
                final Bobs27Game game => _dartKeys(game, bobs27Keys(game)),
                final BaseballGame game => _dartKeys(
                  game,
                  ringKeys(game.inning),
                ),
                final ShanghaiGame game => ShanghaiInput(
                  key: ValueKey(game.visitsPlayed),
                  number: game.currentNumber,
                  dartsInVisit: game.dartsInVisit,
                  onDart: controller.throwDart,
                  onEndVisit: controller.endVisit,
                  onUndo: onUndo,
                ),
                final X01Game game => VisitInput(
                  key: ValueKey(game.visitsPlayed),
                  onSubmit: (score) => _submit(context, game, score),
                  onDart: controller.throwDart,
                  dartsInVisit: game.dartsInVisit,
                  onEndVisit: controller.endVisit,
                  onUndo: onUndo,
                ),
                final CricketGame game
                    when game.config.input == CricketInput.board =>
                  CricketBoardInput(
                    dartsInVisit: game.dartsInVisit,
                    onDart: controller.throwDart,
                    onEndVisit: controller.endVisit,
                    onUndo: onUndo,
                  ),
                CricketGame() => VisitInput(
                  key: ValueKey(game.visitsPlayed),
                  onSubmit: null,
                  onDart: controller.throwDart,
                  dartsInVisit: game.dartsInVisit,
                  onEndVisit: controller.endVisit,
                  onUndo: onUndo,
                ),
              };
        return Stack(
          children: [
            Column(
              children: [
                _GameBar(
                  label: [
                    // In a match, the score matters more than the rules.
                    switch (controller.state.match) {
                      final match? =>
                        '${matchScoreHeading(match)} : '
                            '${matchScoreLabel(match, controller.state.matchPlayers)}',
                      null => configLabel(game.config),
                    },
                  ].join('  ·  '),
                ),
                // A team's score has one name on it, and a session has
                // distractions: say in full view whose throw it is.
                if (game.activePlayer.isTeam && !game.isFinished)
                  _ThrowerBanner(
                    team: game.activePlayer,
                    thrower: game.thrower,
                  ),
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

    return PopScope(
      // Back during a game cancels it rather than leaving it behind.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: _scaffold(launcher, gameBody),
    );
  }

  Widget _scaffold(SessionLauncher? launcher, Widget gameBody) {
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

  /// Back: between games, leaves to the menu, the session staying open.
  /// During a game, cancels it — after asking, if anything was entered —
  /// and reopens the setup it was started with.
  Future<void> _onBack() async {
    final game = controller.state.game;
    final onCancelGame = widget.onCancelGame;
    if (game == null ||
        game.isFinished ||
        controller.state.isEnded ||
        onCancelGame == null) {
      Navigator.of(context).pop();
      return;
    }
    if (_cancelling) return;
    _cancelling = true;
    try {
      if (controller.canUndo) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Annuler la partie ?'),
            content: const Text(
              'Ce qui a été joué dans cette partie sera effacé. Vous '
              'revenez au choix des joueurs et du jeu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuer la partie'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Annuler la partie'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      final cancelled = (players: game.players, config: game.config);
      controller.cancelGame();
      final started = await onCancelGame(cancelled);
      // Backing out of the setup too: nothing is left to play here.
      if (!started && mounted) Navigator.of(context).pop();
    } finally {
      _cancelling = false;
    }
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

  /// The input of a game thrown at one target at a time.
  Widget _dartKeys(Game game, List<DartKey> keys) => DartKeysInput(
    key: ValueKey(game.visitsPlayed),
    keys: keys,
    dartsInVisit: game.dartsInVisit,
    onDart: controller.throwDart,
    onEndVisit: controller.endVisit,
    onUndo: controller.canUndo ? _undo : null,
  );

  /// A visit total of a game without checkouts.
  void _submitTotal(BuildContext context, int score) =>
      _reportIfRejected(context, controller.submitVisitTotal(score), score);

  void _reportIfRejected(
    BuildContext context,
    CommandResult result,
    int score,
  ) {
    if (result is! Rejected || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Score invalide : $score')));
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
    int? dartsAtDouble;
    if (game.config.trackDoubles) {
      final counts = game.doubleDartOptions(
        score,
        dartsAtCheckout: dartsAtCheckout,
      );
      if (counts.length == 1) {
        dartsAtDouble = counts.single;
      } else if (counts.isNotEmpty) {
        dartsAtDouble = await _askDoubleDarts(context, counts);
        if (dartsAtDouble == null || !context.mounted) return;
      }
    }
    final result = controller.submitVisitTotal(
      score,
      dartsAtCheckout: dartsAtCheckout,
      dartsAtDouble: dartsAtDouble,
    );
    if (context.mounted) _reportIfRejected(context, result, score);
  }
}

/// Asks how many darts of the visit were thrown at a finish; null if
/// dismissed.
Future<int?> _askDoubleDarts(BuildContext context, List<int> counts) {
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('double-darts-dialog'),
      title: const Text('Fléchettes sur un double ?'),
      actions: [
        for (final count in counts)
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(count),
            child: Text('$count'),
          ),
      ],
    ),
  );
}

/// Who of which team is at the oche, for as long as it is their visit.
class _ThrowerBanner extends StatelessWidget {
  const _ThrowerBanner({required this.team, required this.thrower});

  final Player team;
  final Player thrower;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const Key('thrower-banner'),
      width: double.infinity,
      color: tokens.activePlayer,
      padding: const EdgeInsets.symmetric(
        horizontal: DartsSpace.lg,
        vertical: DartsSpace.sm,
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${thrower.name} lance',
              style: textTheme.headlineMedium?.copyWith(
                color: tokens.onActivePlayer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Équipe ${team.name}',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.onActivePlayer,
              ),
            ),
          ),
        ],
      ),
    );
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
    final match = session.match;
    final matchIsOpen = match != null && match.winner == null;
    final onChangeSetup = this.onChangeSetup;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(switch (match) {
              null => '${game.winner!.name} gagne !',
              MatchScore(winner: null) =>
                '${game.winner!.name} gagne la manche',
              MatchScore() => '${game.winner!.name} gagne le match !',
            }, style: textTheme.headlineMedium),
            if (match != null) ...[
              const SizedBox(height: DartsSpace.xs),
              Text(
                '${matchScoreHeading(match)} : '
                '${matchScoreLabel(match, session.matchPlayers)}',
                key: const Key('match-score'),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: DartsSpace.sm),
            StatsTableView(
              key: const Key('game-averages'),
              stats: gameOverStats(session),
            ),
            const SizedBox(height: DartsSpace.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onRematch,
                icon: const Icon(Icons.replay),
                // The text theme's colour is the surface's: on a filled
                // button it would be light on light.
                label: Text(
                  matchIsOpen ? 'Manche suivante' : 'Rejouer',
                  style: textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
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
                    KillerGame() ||
                    HalveItGame() ||
                    GolfGame() ||
                    AroundTheClockGame() ||
                    Bobs27Game() ||
                    BaseballGame() => 'Annuler la dernière fléchette',
                    CountUpGame() => 'Annuler la dernière saisie',
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
