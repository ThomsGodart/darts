/// Outcome of a command sent to the [Session] facade.
sealed class CommandResult {
  const CommandResult();
}

/// The command was applied and recorded in the journal.
class Accepted extends CommandResult {
  const Accepted();
}

/// The command was refused; the state is unchanged.
class Rejected extends CommandResult {
  const Rejected(this.reason);

  final String reason;

  @override
  String toString() => 'Rejected($reason)';
}
