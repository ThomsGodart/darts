import 'player.dart';
import 'x01_config.dart';

/// A fact recorded in a soirée's journal. The state is a fold of these.
sealed class SoireeEvent {
  const SoireeEvent();
}

class GameStarted extends SoireeEvent {
  const GameStarted({required this.players, required this.config});

  /// Players in throwing order.
  final List<Player> players;
  final X01Config config;
}

/// A visit entered as its total (0–180).
class VisitTotalSubmitted extends SoireeEvent {
  const VisitTotalSubmitted(this.score, {this.darts = dartsPerVisit});

  final int score;

  /// Darts thrown: a full visit, unless the visit checked out in fewer.
  final int darts;
}
