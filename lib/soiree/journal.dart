import 'events.dart';

/// Ordered log of a soirée's events: the source of truth for its state.
abstract interface class SoireeJournal {
  List<SoireeEvent> get events;

  void append(SoireeEvent event);

  /// Drops the latest event; the journal must not be empty.
  void removeLast();
}

class InMemoryJournal implements SoireeJournal {
  final List<SoireeEvent> _events = [];

  @override
  List<SoireeEvent> get events => List.unmodifiable(_events);

  @override
  void append(SoireeEvent event) => _events.add(event);

  @override
  void removeLast() => _events.removeLast();
}
