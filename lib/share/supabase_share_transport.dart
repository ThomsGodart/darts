import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'share_transport.dart';

/// Shares sessions over Supabase Realtime broadcast: nothing is stored,
/// and nobody signs in. The client is only made when a line first opens,
/// so that an app that never shares never touches the network.
class SupabaseShareTransport implements ShareTransport {
  SupabaseShareTransport(this._url, this._publishableKey);

  static const _event = 'share';

  final String _url;
  final String _publishableKey;
  SupabaseClient? _client;

  @override
  Future<ShareLine> open(String code) async {
    final client = _client ??= SupabaseClient(_url, _publishableKey);
    final channel = client.channel('darts-share:$code');
    final line = _SupabaseLine(client, channel);
    final opened = Completer<void>();
    channel
        .onBroadcast(
          event: _event,
          callback: (payload) {
            if (!line._messages.isClosed) line._messages.add(payload);
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            if (!opened.isCompleted) {
              opened.complete();
            } else if (!line._rejoined.isClosed) {
              line._rejoined.add(null);
            }
          } else if (!opened.isCompleted &&
              status != RealtimeSubscribeStatus.closed) {
            opened.completeError(ShareUnreachable(error ?? status));
          }
        });
    try {
      await opened.future.timeout(const Duration(seconds: 10));
    } catch (error) {
      await line.close();
      throw error is ShareUnreachable ? error : ShareUnreachable(error);
    }
    return line;
  }
}

class _SupabaseLine implements ShareLine {
  _SupabaseLine(this._client, this._channel);

  final SupabaseClient _client;
  final RealtimeChannel _channel;
  final _messages = StreamController<ShareMessage>.broadcast();
  final _rejoined = StreamController<void>.broadcast();

  @override
  Stream<ShareMessage> get messages => _messages.stream;

  @override
  Stream<void> get rejoined => _rejoined.stream;

  @override
  void send(ShareMessage message) {
    unawaited(
      _channel
          .sendBroadcastMessage(
            event: SupabaseShareTransport._event,
            payload: {...message},
          )
          .then<void>((_) {})
          .catchError((Object error) {
            debugPrint('Share message not sent: $error');
          }),
    );
  }

  @override
  Future<void> close() async {
    try {
      await _client.removeChannel(_channel);
    } catch (error) {
      debugPrint('Share line not closed cleanly: $error');
    }
    unawaited(_messages.close());
    unawaited(_rejoined.close());
  }
}
