import 'events.dart';

/// Ordered log of a session's events: the source of truth for its state.
abstract interface class SessionJournal {
  List<SessionEvent> get events;

  void append(SessionEvent event);

  /// Drops the latest event; the journal must not be empty.
  void removeLast();
}

class InMemoryJournal implements SessionJournal {
  InMemoryJournal();

  /// A journal holding [events] already, e.g. read back from storage.
  InMemoryJournal.of(Iterable<SessionEvent> events) {
    _events.addAll(events);
  }

  final List<SessionEvent> _events = [];

  @override
  List<SessionEvent> get events => List.unmodifiable(_events);

  @override
  void append(SessionEvent event) => _events.add(event);

  @override
  void removeLast() => _events.removeLast();
}
