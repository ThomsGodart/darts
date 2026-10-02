import 'commands.dart';
import 'events.dart';
import 'fold.dart';
import 'journal.dart';
import 'player.dart';
import 'state.dart';
import 'x01_config.dart';

/// Single entry point to the soirée domain.
///
/// Commands are validated against the current state; accepted ones are
/// appended to the [SoireeJournal] and folded into a new [state].
class Soiree {
  Soiree(this._journal) : _state = foldEvents(_journal.events);

  final SoireeJournal _journal;
  SoireeState _state;

  SoireeState get state => _state;

  CommandResult startGame(
    List<Player> players, {
    X01Config config = const X01Config(),
  }) {
    if (players.isEmpty) return const Rejected('A game needs players');
    if (!config.isValid) {
      return Rejected('Invalid start score ${config.startScore}');
    }
    final game = _state.game;
    if (game != null && !game.isFinished) {
      return const Rejected('A game is already in progress');
    }
    return _record(
      GameStarted(players: List.unmodifiable(players), config: config),
    );
  }

  CommandResult submitVisitTotal(int score) {
    final game = _state.game;
    if (game == null) return const Rejected('No game in progress');
    if (game.isFinished) return const Rejected('The game is over');
    if (score < 0 || score > 180) {
      return Rejected('A visit scores between 0 and 180, not $score');
    }
    return _record(VisitTotalSubmitted(score));
  }

  CommandResult _record(SoireeEvent event) {
    _journal.append(event);
    _state = applyEvent(_state, event);
    return const Accepted();
  }
}
