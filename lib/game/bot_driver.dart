import 'dart:async';
import 'dart:math';

import '../session/session.dart';
import '../session_controller.dart';

/// Throws for the virtual opponents of a session: whenever one is up, it
/// enters its visit after [delay], unless the visit was entered or taken
/// back meanwhile.
///
/// On a shared session every device runs one; a guest's waits longer, so
/// that it only throws when the device that shares does not.
class BotDriver {
  BotDriver(this._controller, {required this.delay, Random? random})
    : _random = random ?? Random() {
    _controller.addListener(_schedule);
    _schedule();
  }

  final SessionController _controller;

  /// How long a virtual opponent takes to throw.
  final Duration delay;
  final Random _random;
  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_schedule);
  }

  void _schedule() {
    _timer?.cancel();
    final state = _controller.state;
    final game = state.game;
    // In a team, the bot throws when its turn comes among the members.
    if (game == null ||
        game.isFinished ||
        state.isEnded ||
        !game.thrower.isBot) {
      return;
    }
    final games = state.games.length;
    final visits = game.visitsPlayed;
    _timer = Timer(delay, () {
      final now = _controller.state.game;
      // Undone or replaced meanwhile: this visit is no longer due.
      if (now == null ||
          _controller.state.games.length != games ||
          now.visitsPlayed != visits ||
          now.isFinished) {
        return;
      }
      switch (now) {
        case X01Game():
          final visit = botVisit(now, _random);
          _controller.submitVisitTotal(
            visit.score,
            dartsAtCheckout: visit.dartsAtCheckout,
          );
        case CountUpGame():
          _controller.submitVisitTotal(
            botCountUpVisit(now.thrower.botAverage!, _random),
          );
        default:
          // The setup only lets a virtual opponent into these two games.
          break;
      }
    });
  }
}
