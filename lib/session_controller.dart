import 'package:flutter/foundation.dart';

import 'session/session.dart';

/// Exposes the [Session] facade to widgets; widgets never touch the domain
/// or storage directly.
class SessionController extends ChangeNotifier {
  SessionController(this._session);

  final Session _session;

  SessionState get state => _session.state;

  CommandResult startGame(
    List<Player> players, {
    GameConfig config = const X01Config(),
  }) => _notifyIfAccepted(_session.startGame(players, config: config));

  CommandResult submitVisitTotal(
    int score, {
    int? dartsAtCheckout,
    int? dartsAtDouble,
  }) => _notifyIfAccepted(
    _session.submitVisitTotal(
      score,
      dartsAtCheckout: dartsAtCheckout,
      dartsAtDouble: dartsAtDouble,
    ),
  );

  CommandResult throwDart(Dart dart) =>
      _notifyIfAccepted(_session.throwDart(dart));

  CommandResult endVisit() => _notifyIfAccepted(_session.endVisit());

  CommandResult assignNumber(int sector) =>
      _notifyIfAccepted(_session.assignNumber(sector));

  CommandResult rematch({GameConfig? config}) =>
      _notifyIfAccepted(_session.rematch(config: config));

  CommandResult endSession() => _notifyIfAccepted(_session.endSession());

  /// Setup of the next game: same rules, the rotated throwing order.
  GameSetup? get nextSetup {
    final game = state.game;
    return game == null
        ? null
        : (players: game.rematchOrder, config: game.config);
  }

  bool get canUndo => _session.canUndo;

  CommandResult undo() => _notifyIfAccepted(_session.undo());

  CommandResult _notifyIfAccepted(CommandResult result) {
    if (result is Accepted) notifyListeners();
    return result;
  }
}
