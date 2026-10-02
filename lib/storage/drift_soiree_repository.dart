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

  @override
  Future<Soiree> create() async {
    await flush();
    final id = await _db.into(_db.soirees).insert(SoireesCompanion.insert());
    return Soiree(_DriftJournal(id, const [], _enqueue, _db));
  }

  @override
  Future<Soiree?> latest() async {
    await flush();
    final soiree =
        await (_db.select(_db.soirees)
              ..orderBy([(s) => OrderingTerm.desc(s.id)])
              ..limit(1))
            .getSingleOrNull();
    if (soiree == null) return null;
    final rows =
        await (_db.select(_db.soireeEvents)
              ..where((e) => e.soireeId.equals(soiree.id))
              ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
            .get();
    final events = [
      for (final row in rows)
        decodeEvent(row.type, jsonDecode(row.payload) as Map<String, Object?>),
    ];
    return Soiree(_DriftJournal(soiree.id, events, _enqueue, _db));
  }

  @override
  Future<void> flush() => _writes;

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) => write()).catchError((Object error) {
      // The game goes on from memory; only its persistence is lost.
      debugPrint('Could not store a soirée event: $error');
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
