import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../session/event_codec.dart';
import '../session/events.dart';
import '../session/session.dart';
import '../session_controller.dart';
import 'share_protocol.dart';
import 'share_transport.dart';

/// Nobody shares a session under the code that was asked.
class NoSuchShare implements Exception {
  const NoSuchShare();
}

/// The session under the code is shared by a build of the app this one
/// cannot talk to.
class IncompatibleShare implements Exception {
  const IncompatibleShare();
}

/// Shares the session of a [SessionController] with other devices, under
/// a code: every device holds the whole journal, shows the same game and
/// may enter into it.
///
/// One device shares, and stores the session; the others are guests that
/// [join] it, and only play it. Each change of the journal gets a
/// version; a device sends what changed since the version before, and
/// one that missed a version asks for the whole journal. When two
/// devices enter at the same time, the higher version stands and the
/// other input is lost: the players see it on every screen.
///
/// The device that shares does not take everything: what was played
/// before the game in hand cannot be rewritten from the line, and
/// nothing can once it [lockInput]s.
class SessionShare extends ChangeNotifier {
  /// Shares the session of [controller], under [code] when it was shared
  /// under one before. Nothing goes on the line until [start].
  SessionShare(
    this._transport,
    this.controller, {
    this._code,
    bool lockInput = false,
    Random? random,
  }) : isGuest = false,
       _inputLocked = lockInput,
       _random = random ?? Random.secure() {
    _init();
  }

  SessionShare._guest(this._transport, Random? random)
    : isGuest = true,
      controller = SessionController(Session(InMemoryJournal())),
      _random = random ?? Random.secure() {
    _init();
  }

  /// Joins the session shared under [code] and takes its journal, into a
  /// controller of its own. Throws [NoSuchShare] when nobody answers
  /// within [timeout], [IncompatibleShare] when who answers cannot be
  /// understood, and [ShareUnreachable] without network.
  static Future<SessionShare> join(
    ShareTransport transport,
    String code, {
    Duration timeout = const Duration(seconds: 6),
    Random? random,
  }) async {
    final share = SessionShare._guest(transport, random);
    try {
      await share._join(code, timeout);
    } catch (_) {
      share.dispose();
      rethrow;
    }
    return share;
  }

  /// Tells the guests of the session shared under [code] that it was
  /// ended away from the line. Best effort: without network they are
  /// simply not told.
  static Future<void> announceGone(
    ShareTransport transport,
    String code,
  ) async {
    try {
      final line = await transport.open(code);
      line.send(const SessionGone(from: 'gone').toWire());
      await line.close();
    } on ShareUnreachable {
      // Nobody to tell.
    }
  }

  static const codeLength = 6;

  final ShareTransport _transport;

  /// The session on the line: a guest's is made on joining, and goes
  /// with the share.
  final SessionController controller;

  /// Whether this device joined a session another one shares.
  final bool isGuest;

  final Random _random;
  late final String _device = _digits(9);

  String? _code;
  ShareLine? _line;
  final List<StreamSubscription<void>> _subscriptions = [];
  Future<void>? _starting;
  bool _disposed = false;

  /// The journal as the devices last agreed on it, one text per event.
  List<String> _wire = const [];
  JournalVersion _version = noJournal;

  /// Set while a journal from the line goes into the controller, whose
  /// notification is then not a change to send.
  bool _adopting = false;
  Completer<void>? _firstJournal;
  final Set<String> _joined = {};
  bool _wanted = false;
  bool _carrying = false;
  bool _inputLocked = false;
  bool _incompatible = false;

  /// What the other devices type to join; null before the first [start].
  /// Stays the same when the share is stopped and started again.
  String? get code => _code;

  /// Whether the session is on the line.
  bool get isOn => _line != null;

  /// Whether the players want the session shared: from [start] until
  /// [stop], even while the network keeps it off the line.
  bool get isWanted => _wanted;

  /// Whether the line carries messages right now. False while [isOn]
  /// means the network dropped: what shows may be out of date.
  bool get isCarrying => _carrying;

  /// Whether the session should be on the line and is not, or not in a
  /// way that carries: the network dropped, or never let it open.
  bool get isOffLine => isOn ? !_carrying : _wanted;

  /// How many devices joined since the share was started.
  int get joinedCount => _joined.length;

  /// Whether only the device that shares enters: its guests are screens.
  bool get inputLocked => _inputLocked;

  /// Whether a device on the line runs a build this one cannot talk to.
  bool get hasIncompatiblePeer => _incompatible;

  /// Keeps the input to this device, or opens it to the guests again.
  void lockInput(bool locked) {
    assert(!isGuest, 'Only the device that shares locks the input');
    if (locked == _inputLocked) return;
    _inputLocked = locked;
    _hello();
    notifyListeners();
  }

  /// Puts the session on the line, under [code] or a new one. Throws
  /// [ShareUnreachable] without network; the share then stays wanted,
  /// and tries again each time something is entered.
  Future<void> start() {
    assert(!isGuest, 'A guest is on the line from joining');
    _wanted = true;
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<void> _start() async {
    if (isOn) return;
    try {
      if (!await _open(_code ?? _digits(codeLength))) return;
    } on ShareUnreachable {
      // Wanted, and off the line: say so.
      if (!_disposed) notifyListeners();
      rethrow;
    }
    final wire = _encode(controller.events);
    if (_version == noJournal || !listEquals(wire, _wire)) {
      _wire = wire;
      _version = (rev: _version.rev + 1, origin: _device);
    }
    // A device that went on alone under this code may be ahead.
    _hello();
    notifyListeners();
  }

  Future<void> _join(String code, Duration timeout) async {
    if (!await _open(code)) return;
    final first = _firstJournal = Completer<void>();
    // The line may not carry the first one: ask until someone answers.
    final asking = Timer.periodic(const Duration(seconds: 1), (_) => _hello());
    _hello();
    try {
      await first.future.timeout(timeout);
    } on TimeoutException {
      throw _incompatible ? const IncompatibleShare() : const NoSuchShare();
    } finally {
      asking.cancel();
      _firstJournal = null;
    }
  }

  /// Takes the session off the line; the other devices keep what they
  /// have.
  void stop() {
    _wanted = false;
    if (_close()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    controller.removeListener(_onLocalChange);
    _close();
    if (isGuest) controller.dispose();
    super.dispose();
  }

  void _init() => controller.addListener(_onLocalChange);

  /// Says whether the line was opened: not when the share was disposed
  /// of meanwhile.
  Future<bool> _open(String code) async {
    final line = await _transport.open(code);
    if (_disposed) {
      unawaited(line.close());
      return false;
    }
    _code = code;
    _line = line;
    _carrying = true;
    _subscriptions
      ..add(line.messages.listen(_onMessage))
      ..add(line.carrying.listen(_onCarrying));
    return true;
  }

  bool _close() {
    final line = _line;
    if (line == null) return false;
    _line = null;
    _carrying = false;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _joined.clear();
    unawaited(line.close());
    return true;
  }

  void _onCarrying(bool carrying) {
    _carrying = carrying;
    // Back on the line: whoever is ahead says so.
    if (carrying) _hello();
    notifyListeners();
  }

  void _onLocalChange() {
    if (_adopting) return;
    if (!isOn) {
      // Wanted but kept off the line by the network: every input is a
      // reason to try again, and starting sends what was entered since.
      if (_wanted) unawaited(start().catchError((Object _) {}));
      return;
    }
    final wire = _encode(controller.events);
    if (listEquals(wire, _wire)) return;
    final keep = _commonPrefix(wire, _wire);
    final base = _version;
    _version = (rev: base.rev + 1, origin: _device);
    _wire = wire;
    _send(
      JournalChange(
        from: _device,
        locked: _lockSaid,
        version: _version,
        base: base,
        keep: keep,
        tail: wire.sublist(keep),
      ),
    );
  }

  void _onMessage(ShareMessage message) {
    final ShareSignal signal;
    try {
      signal = ShareSignal.fromWire(message);
    } on IncompatibleSignal {
      if (!_incompatible) {
        _incompatible = true;
        notifyListeners();
      }
      return;
    } on FormatException catch (error) {
      debugPrint('Share message ignored: $error');
      return;
    }
    // Only the device that shares says whether the input is its own.
    if (signal.locked case final locked? when isGuest) {
      if (locked != _inputLocked) {
        _inputLocked = locked;
        notifyListeners();
      }
    }
    switch (signal) {
      case Hello(:final version):
        if (version == noJournal &&
            _version != noJournal &&
            _joined.add(signal.from)) {
          notifyListeners();
        }
        final ahead = compareVersions(version, _version);
        if (ahead < 0) _sendJournal();
        if (ahead > 0) _hello();
      case WholeJournal(:final version, :final events):
        final ahead = compareVersions(version, _version);
        if (ahead > 0) _adopt(version, events);
        if (ahead < 0) _sendJournal();
      case JournalChange(:final version, :final base, :final keep, :final tail):
        final ahead = compareVersions(version, _version);
        if (base == _version && keep <= _wire.length) {
          _adopt(version, [..._wire.take(keep), ...tail]);
        } else if (ahead > 0) {
          _hello();
        } else if (ahead < 0) {
          _sendJournal();
        }
      case SessionGone():
        if (!isGuest || controller.state.isEnded) return;
        _adopting = true;
        controller.endSession();
        _adopting = false;
    }
  }

  /// Takes [wire] as the journal, at the [version] its sender gave it;
  /// or, when it is not one this device takes, stands by its own.
  void _adopt(JournalVersion version, List<String> wire) {
    // What both hold already stays as stored, with the time it was
    // recorded at.
    final keep = _commonPrefix(wire, _wire);
    var taken = isGuest || (!_inputLocked && keep >= _gameInHand);
    if (taken) {
      _adopting = true;
      try {
        taken = controller.rewrite(keep, [
          for (final text in wire.skip(keep)) _decode(text),
        ]) is Accepted;
      } on Object catch (error) {
        // Events this build does not know.
        debugPrint('Shared journal refused: $error');
        taken = false;
      } finally {
        _adopting = false;
      }
    }
    if (!taken) {
      if (isGuest) return;
      // The session is stored here: this journal stands, above theirs.
      _version = (rev: max(_version.rev, version.rev) + 1, origin: _device);
      _sendJournal();
      return;
    }
    _wire = wire;
    _version = version;
    final first = _firstJournal;
    if (first != null && !first.isCompleted) first.complete();
  }

  /// Where the game in hand starts in the journal: what comes before was
  /// played, and is not rewritten from the line.
  int get _gameInHand =>
      max(0, controller.events.lastIndexWhere((e) => e is GameStarted));

  void _hello() =>
      _send(Hello(from: _device, locked: _lockSaid, version: _version));

  /// What this device says of the lock: nothing, as a guest.
  bool? get _lockSaid => isGuest ? null : _inputLocked;

  void _sendJournal() {
    if (_version == noJournal) return;
    _send(
      WholeJournal(
        from: _device,
        locked: _lockSaid,
        version: _version,
        events: _wire,
      ),
    );
  }

  void _send(ShareSignal signal) => _line?.send(signal.toWire());

  String _digits(int length) =>
      [for (var i = 0; i < length; i++) _random.nextInt(10)].join();

  static List<String> _encode(List<SessionEvent> events) => [
    for (final event in events)
      if (encodeEvent(event) case (:final type, :final payload))
        jsonEncode({'t': type, 'p': payload}),
  ];

  static SessionEvent _decode(String text) {
    final stored = jsonDecode(text) as Map<String, Object?>;
    return decodeEvent(
      stored['t']! as String,
      stored['p']! as Map<String, Object?>,
    );
  }

  static int _commonPrefix(List<String> a, List<String> b) {
    var length = 0;
    while (length < a.length && length < b.length && a[length] == b[length]) {
      length++;
    }
    return length;
  }
}
