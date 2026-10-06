import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../session/event_codec.dart';
import '../session/session.dart';
import '../session_controller.dart';
import 'share_transport.dart';

/// Nobody shares a session under the code that was asked.
class NoSuchShare implements Exception {
  const NoSuchShare();
}

/// Shares the session of a [SessionController] with other devices, under
/// a code: every device holds the whole journal, shows the same game and
/// may enter into it.
///
/// Each change of the journal gets a version, a count and the device that
/// made it. A device sends what changed since the version before; one
/// that missed a version asks for the whole journal. When two devices
/// enter at the same time, the higher version stands and the other input
/// is lost: the players see it on every screen.
class SessionShare extends ChangeNotifier {
  SessionShare(this._transport, this._controller, {this._code, Random? random})
    : _random = random ?? Random.secure() {
    _device = _digits(9);
    _controller.addListener(_onLocalChange);
  }

  static const codeLength = 6;

  final ShareTransport _transport;
  final SessionController _controller;
  final Random _random;
  late final String _device;

  String? _code;
  ShareLine? _line;
  final List<StreamSubscription<void>> _subscriptions = [];

  /// The journal as the devices last agreed on it, one text per event.
  List<String> _wire = const [];

  /// The version of [_wire]: zero until this device holds a journal.
  int _rev = 0;
  String _origin = '';

  /// Set while a journal from the line goes into the controller, whose
  /// notification is then not a change to send.
  bool _adopting = false;
  Completer<void>? _firstJournal;
  final Set<String> _joined = {};

  /// What the other devices type to join; null before the first [start].
  /// Stays the same when the share is stopped and started again.
  String? get code => _code;

  /// Whether the session is on the line.
  bool get isOn => _line != null;

  /// How many devices joined since the share was started.
  int get joinedCount => _joined.length;

  /// Puts the session on the line, under [code] or a new one. Throws
  /// [ShareUnreachable] without network.
  Future<void> start() async {
    if (isOn) return;
    await _open(_code ?? _digits(codeLength));
    final wire = _encode(_controller.events);
    if (_rev == 0 || !listEquals(wire, _wire)) {
      _wire = wire;
      _rev++;
      _origin = _device;
    }
    // A device that went on alone under this code may be ahead.
    _hello();
    notifyListeners();
  }

  /// Joins the session shared under [code] and takes its journal: for a
  /// controller that holds nothing yet. Throws [NoSuchShare] when nobody
  /// answers within [timeout], and [ShareUnreachable] without network.
  Future<void> join(
    String code, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    assert(!isOn && _rev == 0 && _controller.events.isEmpty);
    await _open(code);
    final first = _firstJournal = Completer<void>();
    // The line may not carry the first one: ask until someone answers.
    final asking = Timer.periodic(const Duration(seconds: 1), (_) => _hello());
    _hello();
    try {
      await first.future.timeout(timeout);
    } on TimeoutException {
      stop();
      throw const NoSuchShare();
    } finally {
      asking.cancel();
      _firstJournal = null;
    }
    notifyListeners();
  }

  /// Takes the session off the line; the other devices keep what they
  /// have.
  void stop() {
    final line = _line;
    if (line == null) return;
    _line = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _joined.clear();
    unawaited(line.close());
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_onLocalChange);
    final line = _line;
    _line = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    if (line != null) unawaited(line.close());
    super.dispose();
  }

  Future<void> _open(String code) async {
    final line = await _transport.open(code);
    _code = code;
    _line = line;
    _subscriptions
      ..add(line.messages.listen(_onMessage))
      ..add(line.rejoined.listen((_) => _hello()));
  }

  void _onLocalChange() {
    if (_adopting || !isOn) return;
    final wire = _encode(_controller.events);
    if (listEquals(wire, _wire)) return;
    final keep = _commonPrefix(wire, _wire);
    _send('delta', {
      'baseRev': _rev,
      'baseOrigin': _origin,
      'rev': ++_rev,
      'origin': _origin = _device,
      'keep': keep,
      'tail': wire.sublist(keep),
    });
    _wire = wire;
  }

  void _onMessage(ShareMessage message) {
    try {
      final rev = message['rev']! as int;
      final origin = message['origin']! as String;
      // Above zero: their journal is ahead of this device's.
      final ahead = rev != _rev ? rev - _rev : origin.compareTo(_origin);
      switch (message['kind']) {
        case 'hello':
          if (rev == 0 && _rev > 0 && _joined.add(message['from']! as String)) {
            notifyListeners();
          }
          if (ahead < 0) _sendJournal();
          if (ahead > 0) _hello();
        case 'journal':
          if (ahead > 0) {
            _adopt(rev, origin, (message['events']! as List).cast<String>());
          } else if (ahead < 0) {
            _sendJournal();
          }
        case 'delta':
          if (message['baseRev'] == _rev && message['baseOrigin'] == _origin) {
            _adopt(rev, origin, [
              ..._wire.take(message['keep']! as int),
              ...(message['tail']! as List).cast<String>(),
            ]);
          } else if (ahead > 0) {
            _hello();
          } else if (ahead < 0) {
            _sendJournal();
          }
      }
    } catch (error) {
      // Not a message of this app, or of a version that speaks otherwise.
      debugPrint('Share message ignored: $error');
    }
  }

  /// Takes [wire] as the journal, at the version its sender gave it.
  void _adopt(int rev, String origin, List<String> wire) {
    // What both hold already stays as stored, with the time it was
    // recorded at.
    final keep = _commonPrefix(wire, _wire);
    _adopting = true;
    try {
      final result = _controller.rewrite(keep, [
        for (final text in wire.skip(keep)) _decode(text),
      ]);
      if (result is Rejected) throw FormatException(result.reason);
    } finally {
      _adopting = false;
    }
    _wire = wire;
    _rev = rev;
    _origin = origin;
    final first = _firstJournal;
    if (first != null && !first.isCompleted) first.complete();
  }

  void _hello() => _send('hello', {'rev': _rev, 'origin': _origin});

  void _sendJournal() {
    if (_rev == 0) return;
    _send('journal', {'rev': _rev, 'origin': _origin, 'events': _wire});
  }

  void _send(String kind, ShareMessage body) =>
      _line?.send({'kind': kind, 'from': _device, ...body});

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
