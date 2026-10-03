import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../soiree/event_codec.dart';
import '../soiree/soiree.dart';
import 'app_database.dart';

/// Keeps soirées in the app's SQLite database.
class DriftSoireeRepository implements SoireeRepository {
  DriftSoireeRepository(this._db);

  final AppDatabase _db;

  /// Writes run one after the other, in the order commands were accepted.
  Future<void> _writes = Future.value();

  /// The first write that failed. Once set, nothing more is written: a
  /// journal with a hole would replay into a different game.
  Object? _failure;

  @override
  Future<Soiree> create() async {
    await _writes;
    final id = await _db.into(_db.soirees).insert(SoireesCompanion.insert());
    return Soiree(_DriftJournal(id, const [], _enqueue, _db));
  }

  @override
  Future<Soiree?> latest() async {
    await _writes;
    final soiree =
        await (_db.select(_db.soirees)
              ..orderBy([(s) => OrderingTerm.desc(s.id)])
              ..limit(1))
            .getSingleOrNull();
    if (soiree == null) return null;
    final events = await _eventsOf(soiree.id);
    return Soiree(_DriftJournal(soiree.id, events, _enqueue, _db));
  }

  @override
  Future<List<SoireeRecord>> history() async {
    await _writes;
    final soirees = await (_db.select(
      _db.soirees,
    )..orderBy([(s) => OrderingTerm.desc(s.id)])).get();
    final records = <SoireeRecord>[];
    for (final soiree in soirees) {
      final state = Soiree(InMemoryJournal.of(await _eventsOf(soiree.id)))
          .state;
      if (state.game == null) continue;
      records.add(
        SoireeRecord(
          id: '${soiree.id}',
          createdAt: soiree.createdAt,
          state: state,
        ),
      );
    }
    return records;
  }

  @override
  Future<void> delete(String id) async {
    await _writes;
    final soireeId = int.tryParse(id);
    if (soireeId == null) return;
    await _db.transaction(() async {
      await (_db.delete(
        _db.soireeEvents,
      )..where((e) => e.soireeId.equals(soireeId))).go();
      await (_db.delete(_db.soirees)..where((s) => s.id.equals(soireeId))).go();
    });
  }

  Future<List<SoireeEvent>> _eventsOf(int soireeId) async {
    final rows =
        await (_db.select(_db.soireeEvents)
              ..where((e) => e.soireeId.equals(soireeId))
              ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
            .get();
    return [
      for (final row in rows)
        decodeEvent(row.type, jsonDecode(row.payload) as Map<String, Object?>),
    ];
  }

  /// Completes once every write has run; throws if one of them failed.
  @override
  Future<void> flush() async {
    await _writes;
    if (_failure case final failure?) throw failure;
  }

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) async {
      if (_failure != null) return;
      try {
        await write();
      } catch (error) {
        // The game goes on from memory; what is stored stays a consistent
        // prefix of it.
        _failure = error;
        debugPrint('Stopped storing soirée events: $error');
      }
    });
  }
}

/// A soirée's journal: read from memory, written through to the database.
class _DriftJournal implements SoireeJournal {
  _DriftJournal(
    this._soireeId,
    List<SoireeEvent> events,
    this._enqueue,
    this._db,
  ) : _events = [...events];

  final int _soireeId;
  final List<SoireeEvent> _events;
  final void Function(Future<void> Function()) _enqueue;
  final AppDatabase _db;

  @override
  List<SoireeEvent> get events => List.unmodifiable(_events);

  @override
  void append(SoireeEvent event) {
    final seq = _events.length;
    _events.add(event);
    final encoded = encodeEvent(event);
    _enqueue(
      () => _db
          .into(_db.soireeEvents)
          .insert(
            SoireeEventsCompanion.insert(
              soireeId: _soireeId,
              seq: seq,
              type: encoded.type,
              payload: jsonEncode(encoded.payload),
            ),
          ),
    );
  }

  @override
  void removeLast() {
    _events.removeLast();
    final seq = _events.length;
    _enqueue(
      () => (_db.delete(
        _db.soireeEvents,
      )..where((e) => e.soireeId.equals(_soireeId) & e.seq.equals(seq))).go(),
    );
  }
}
