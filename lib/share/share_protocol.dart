import 'share_transport.dart';

/// The version of a journal on the line: how many times it changed, and
/// the device that changed it last. Zero is a device holding none yet.
typedef JournalVersion = ({int rev, String origin});

const noJournal = (rev: 0, origin: '');

/// Above zero when [a] is ahead of [b].
int compareVersions(JournalVersion a, JournalVersion b) =>
    a.rev != b.rev ? a.rev - b.rev : a.origin.compareTo(b.origin);

/// What the devices sharing a session say to each other. Events travel
/// as the texts [encodeWireEvent] makes of them.
sealed class ShareSignal {
  const ShareSignal({required this.from, this.locked});

  /// How this build speaks; a message that says otherwise is not read.
  static const protocol = 1;

  /// The largest journal taken from the line, in events and in the size
  /// of one of them: nothing the game produces comes near.
  static const maxEvents = 20000;
  static const maxEventLength = 4000;

  /// The device that sent it.
  final String from;

  /// Whether the device that shares the session keeps the input to
  /// itself; null from a guest, who has no say in it.
  final bool? locked;

  ShareMessage toWire() => {
    'v': protocol,
    'from': from,
    'locked': ?locked,
    ...switch (this) {
      Hello(:final version) => {'kind': 'hello', ..._version(version)},
      WholeJournal(:final version, :final events) => {
        'kind': 'journal',
        ..._version(version),
        'events': events,
      },
      JournalChange(:final version, :final base, :final keep, :final tail) => {
        'kind': 'delta',
        ..._version(version),
        'baseRev': base.rev,
        'baseOrigin': base.origin,
        'keep': keep,
        'tail': tail,
      },
      SessionGone() => {'kind': 'gone'},
    },
  };

  static Map<String, Object?> _version(JournalVersion version) => {
    'rev': version.rev,
    'origin': version.origin,
  };

  /// Reads a message off the line. Throws [IncompatibleSignal] for one
  /// of another protocol, and [FormatException] for anything else that
  /// is not a signal.
  static ShareSignal fromWire(ShareMessage message) {
    if (message['v'] != protocol) throw const IncompatibleSignal();
    try {
      final from = message['from']! as String;
      final locked = message['locked'] as bool?;
      JournalVersion version() =>
          (rev: message['rev']! as int, origin: message['origin']! as String);
      return switch (message['kind']) {
        'hello' => Hello(from: from, locked: locked, version: version()),
        'journal' => WholeJournal(
          from: from,
          locked: locked,
          version: version(),
          events: _events(message['events']),
        ),
        'delta' => JournalChange(
          from: from,
          locked: locked,
          version: version(),
          base: (
            rev: message['baseRev']! as int,
            origin: message['baseOrigin']! as String,
          ),
          keep: message['keep']! as int,
          tail: _events(message['tail']),
        ),
        'gone' => SessionGone(from: from),
        final kind => throw FormatException('Unknown signal "$kind"'),
      };
    } on FormatException {
      rethrow;
    } catch (error) {
      // A missing key or a value of another type.
      throw FormatException('Not a signal: $error');
    }
  }

  static List<String> _events(Object? stored) {
    final events = (stored! as List).cast<String>().toList();
    if (events.length > maxEvents ||
        events.any((event) => event.length > maxEventLength)) {
      throw const FormatException('Too large a journal');
    }
    return events;
  }
}

/// A message of a build that speaks another protocol.
class IncompatibleSignal implements Exception {
  const IncompatibleSignal();
}

/// "Here I am, holding this version": sent on joining, on coming back,
/// and to ask whoever is ahead for the whole journal.
class Hello extends ShareSignal {
  const Hello({required super.from, super.locked, required this.version});

  final JournalVersion version;
}

/// The whole journal at [version].
class WholeJournal extends ShareSignal {
  const WholeJournal({
    required super.from,
    super.locked,
    required this.version,
    required this.events,
  });

  final JournalVersion version;
  final List<String> events;
}

/// What changed from [base] to [version]: the first [keep] events stay,
/// then come [tail].
class JournalChange extends ShareSignal {
  const JournalChange({
    required super.from,
    super.locked,
    required this.version,
    required this.base,
    required this.keep,
    required this.tail,
  });

  final JournalVersion version;
  final JournalVersion base;
  final int keep;
  final List<String> tail;
}

/// The device that shared the session ended it away from the line: there
/// is nothing more to follow.
class SessionGone extends ShareSignal {
  const SessionGone({required super.from});
}
