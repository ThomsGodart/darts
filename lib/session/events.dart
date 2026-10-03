import 'dart.dart';
import 'player.dart';
import 'game_config.dart';

/// A fact recorded in a session's journal. The state is a fold of these.
sealed class SessionEvent {
  const SessionEvent();
}

class GameStarted extends SessionEvent {
  const GameStarted({required this.players, required this.config});

  /// Players in throwing order.
  final List<Player> players;
  final GameConfig config;
}

/// A visit entered as its total (0–180).
class VisitTotalSubmitted extends SessionEvent {
  const VisitTotalSubmitted(this.score, {this.darts = dartsPerVisit});

  final int score;

  /// Darts thrown: a full visit, unless the visit checked out in fewer.
  final int darts;
}

/// The session is over: it goes to the history.
class SessionEnded extends SessionEvent {
  const SessionEnded();
}

/// One dart of a visit entered dart by dart.
class DartThrown extends SessionEvent {
  const DartThrown(this.dart);

  final Dart dart;
}

/// The active player ends their visit before its third dart: the darts
/// left count as misses.
class VisitEnded extends SessionEvent {
  const VisitEnded();
}

/// The active Killer player claims [sector] (1–20) during attribution.
class NumberAssigned extends SessionEvent {
  const NumberAssigned(this.sector);

  final int sector;
}
