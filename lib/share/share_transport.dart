import 'dart:async';

/// What the devices sharing a session send each other: JSON-compatible.
typedef ShareMessage = Map<String, Object?>;

/// Carries messages between the devices sharing a session.
abstract interface class ShareTransport {
  /// Opens the line of the session shared under [code]; throws
  /// [ShareUnreachable] when the network does not answer.
  Future<ShareLine> open(String code);
}

/// One device's end of the line of a shared session.
abstract interface class ShareLine {
  /// What the other devices on the line sent, never this one's own.
  Stream<ShareMessage> get messages;

  /// Whether the line carries messages, each time that changes: false
  /// when the network drops, true when it is back, messages having
  /// perhaps been missed meanwhile. An opened line starts out carrying.
  Stream<bool> get carrying;

  /// Sends to every other device on the line. Never throws: a message
  /// that does not get through is caught up with once the line is back.
  void send(ShareMessage message);

  Future<void> close();
}

/// The network did not let a line open.
class ShareUnreachable implements Exception {
  const ShareUnreachable([this.cause]);

  final Object? cause;

  @override
  String toString() => 'ShareUnreachable($cause)';
}

/// Lines kept in memory, between the transports made on one hub: for
/// tests, each transport standing for a device.
class InMemoryShareHub {
  final Map<String, List<_InMemoryLine>> _lines = {};

  /// Set to have lines fail to open, like a phone without network.
  bool unreachable = false;

  ShareTransport transport() => _InMemoryTransport(this);

  /// How many devices have a line open on [code].
  int linesOn(String code) => _lines[code]?.length ?? 0;

  /// Cuts the lines of [code] off, or puts them back: while cut, nothing
  /// gets in or out of them, as on a phone that lost the network.
  void cut(String code, {bool off = true}) {
    for (final line in [...?_lines[code]]) {
      line._cut = off;
      line._carrying.add(!off);
    }
  }
}

class _InMemoryTransport implements ShareTransport {
  _InMemoryTransport(this._hub);

  final InMemoryShareHub _hub;

  @override
  Future<ShareLine> open(String code) async {
    if (_hub.unreachable) throw const ShareUnreachable();
    final line = _InMemoryLine(_hub, code);
    (_hub._lines[code] ??= []).add(line);
    return line;
  }
}

class _InMemoryLine implements ShareLine {
  _InMemoryLine(this._hub, this._code);

  final InMemoryShareHub _hub;
  final String _code;

  final _messages = StreamController<ShareMessage>.broadcast();
  final _carrying = StreamController<bool>.broadcast();
  bool _cut = false;

  @override
  Stream<ShareMessage> get messages => _messages.stream;

  @override
  Stream<bool> get carrying => _carrying.stream;

  @override
  void send(ShareMessage message) {
    if (_cut) return;
    for (final line in [...?_hub._lines[_code]]) {
      if (line != this && !line._cut && !line._messages.isClosed) {
        line._messages.add({...message});
      }
    }
  }

  @override
  Future<void> close() async {
    _hub._lines[_code]?.remove(this);
    unawaited(_messages.close());
    unawaited(_carrying.close());
  }
}
