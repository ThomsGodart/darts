import 'events.dart';

/// Ordered log of a session's events: the source of truth for its state.
abstract interface class SessionJournal {
  List<SessionEvent> get events;

  void append(SessionEvent event);

  /// Drops the latest event; the journal must not be empty.
  void removeLast();
}

class InMemoryJournal implements SessionJournal {
  InMemoryJournal({this.now = DateTime.now});

  /// A journal holding [events] already, e.g. read back from storage.
  InMemoryJournal.of(Iterable<SessionEvent> events) : now = DateTime.now {
    for (final event in events) {
      append(event);
    }
  }

  /// What time it is when an event is appended.
  final DateTime Function() now;
  final List<DateTime> _recordedAt = [];

  /// When each of [events] was appended, in the same order.
  List<DateTime> get recordedAt => List.unmodifiable(_recordedAt);

  final List<SessionEvent> _events = [];

  @override
  List<SessionEvent> get events => List.unmodifiable(_events);

  @override
  void append(SessionEvent event) {
    _events.add(event);
    _recordedAt.add(now());
  }

  @override
  void removeLast() {
    _events.removeLast();
    _recordedAt.removeLast();
  }
}
