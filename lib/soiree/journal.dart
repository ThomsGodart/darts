import 'events.dart';

/// Ordered log of a soirée's events: the source of truth for its state.
abstract interface class SoireeJournal {
  List<SoireeEvent> get events;

  void append(SoireeEvent event);
}

class InMemoryJournal implements SoireeJournal {
  final List<SoireeEvent> _events = [];

  @override
  List<SoireeEvent> get events => List.unmodifiable(_events);

  @override
  void append(SoireeEvent event) => _events.add(event);
}
