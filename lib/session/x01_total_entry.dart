import 'commands.dart';
import 'game_config.dart';
import 'state.dart';

/// What a visit entered as a total does not say, and the players are
/// asked.
sealed class TotalQuestion {
  const TotalQuestion();
}

/// The total reaches 0: was its last dart one the [outRule] finishes on?
/// If not, the visit busts.
final class FinishingDartQuestion extends TotalQuestion {
  const FinishingDartQuestion(this.outRule);

  final OutRule outRule;
}

/// The visit checks out: in how many darts, one of [options]?
final class CheckoutDartsQuestion extends TotalQuestion {
  const CheckoutDartsQuestion(this.options);

  final List<int> options;
}

/// How many darts of the visit were thrown at a finish, one of [options]?
final class DoubleDartsQuestion extends TotalQuestion {
  const DoubleDartsQuestion(this.options);

  final List<int> options;
}

/// Takes a visit by its total, as [Session.submitVisitTotal] does.
typedef SubmitVisitTotal = CommandResult Function(
  int score, {
  int? dartsAtCheckout,
  int? dartsAtDouble,
  bool missedFinish,
});

/// A visit of [score] being entered as a total in [game]: what the
/// players still have to say about it, one [question] at a time and in
/// the order the rules need the answers, then what there is to submit.
/// What can only be one value is never asked.
class X01TotalEntry {
  const X01TotalEntry(this.game, this.score)
    : _finishes = null,
      _checkoutIn = null,
      _atDouble = null;

  const X01TotalEntry._(
    this.game,
    this.score,
    this._finishes,
    this._checkoutIn,
    this._atDouble,
  );

  final X01Game game;
  final int score;

  /// The answers given so far.
  final bool? _finishes;
  final int? _checkoutIn;
  final int? _atDouble;

  List<int> get _checkoutOptions => game.checkoutDartOptions(score);

  /// Whether the rule has a finishing dart to ask about.
  bool get _asksFinishingDart =>
      _checkoutOptions.isNotEmpty && game.config.outRule != OutRule.straight;

  List<int> get _doubleOptions => game.config.trackDoubles && !missedFinish
      ? game.doubleDartOptions(score, dartsAtCheckout: dartsAtCheckout)
      : const [];

  /// The total equals the remaining score, but its last dart was not one
  /// the out rule finishes on: the visit busts.
  bool get missedFinish => _finishes == false;

  /// Darts the checkout took; null when the visit is none, or while it
  /// has not been said.
  int? get dartsAtCheckout {
    if (missedFinish) return null;
    final options = _checkoutOptions;
    return options.length == 1 ? options.single : _checkoutIn;
  }

  /// Darts thrown at a finish; null when the game does not count them,
  /// or while it has not been said.
  int? get dartsAtDouble {
    final options = _doubleOptions;
    return options.length == 1 ? options.single : _atDouble;
  }

  /// What to ask next; null once the visit can be submitted.
  TotalQuestion? get question {
    if (_asksFinishingDart && _finishes == null) {
      return FinishingDartQuestion(game.config.outRule);
    }
    if (missedFinish) return null;
    final checkout = _checkoutOptions;
    if (checkout.isNotEmpty && dartsAtCheckout == null) {
      return CheckoutDartsQuestion(checkout);
    }
    final doubles = _doubleOptions;
    if (doubles.isNotEmpty && dartsAtDouble == null) {
      return DoubleDartsQuestion(doubles);
    }
    return null;
  }

  /// Answers a [FinishingDartQuestion].
  X01TotalEntry finishingDart(bool wasOne) =>
      X01TotalEntry._(game, score, wasOne, _checkoutIn, _atDouble);

  /// Answers a [CheckoutDartsQuestion].
  X01TotalEntry checkoutIn(int darts) =>
      X01TotalEntry._(game, score, _finishes, darts, _atDouble);

  /// Answers a [DoubleDartsQuestion].
  X01TotalEntry atDouble(int darts) =>
      X01TotalEntry._(game, score, _finishes, _checkoutIn, darts);

  /// Submits the visit with what was answered.
  CommandResult submitTo(SubmitVisitTotal submit) => missedFinish
      ? submit(score, missedFinish: true)
      : submit(
          score,
          dartsAtCheckout: dartsAtCheckout,
          dartsAtDouble: dartsAtDouble,
        );
}
