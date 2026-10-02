import 'package:flutter/foundation.dart';

import 'soiree/soiree.dart';

/// Exposes the [Soiree] facade to widgets; widgets never touch the domain
/// or storage directly.
class SoireeController extends ChangeNotifier {
  SoireeController(this._soiree);

  /// A soirée kept in memory only, until the drift journal lands (ticket 07).
  factory SoireeController.inMemory() =>
      SoireeController(Soiree(InMemoryJournal()));

  final Soiree _soiree;

  SoireeState get state => _soiree.state;

  CommandResult startGame(
    List<Player> players, {
    X01Config config = const X01Config(),
  }) => _notifyIfAccepted(_soiree.startGame(players, config: config));

  CommandResult submitVisitTotal(int score, {int? dartsAtCheckout}) =>
      _notifyIfAccepted(
        _soiree.submitVisitTotal(score, dartsAtCheckout: dartsAtCheckout),
      );

  bool get canUndo => _soiree.canUndo;

  CommandResult undo() => _notifyIfAccepted(_soiree.undo());

  CommandResult _notifyIfAccepted(CommandResult result) {
    if (result is Accepted) notifyListeners();
    return result;
  }
}
