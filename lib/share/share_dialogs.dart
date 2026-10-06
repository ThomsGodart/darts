import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/darts_space.dart';
import 'session_share.dart';
import 'share_transport.dart';

const _unreachable = 'Connexion impossible. Vérifiez le réseau.';

/// Shows the code of [share], putting the session on the line first when
/// it is not. With [canStop], offers to take it off again.
Future<void> showShareDialog(
  BuildContext context,
  SessionShare share, {
  bool canStop = true,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ShareDialog(share: share, canStop: canStop),
);

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.share, required this.canStop});

  final SessionShare share;
  final bool canStop;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  late Future<void> _started = widget.share.start();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final share = widget.share;
    return FutureBuilder(
      future: _started,
      builder: (context, snapshot) {
        final failed = snapshot.hasError;
        final waiting = snapshot.connectionState != ConnectionState.done;
        return AlertDialog(
          title: const Text('Session partagée'),
          content: ListenableBuilder(
            listenable: share,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (waiting)
                  const Padding(
                    padding: EdgeInsets.all(DartsSpace.lg),
                    child: CircularProgressIndicator(),
                  )
                else if (failed)
                  const Text(_unreachable, key: Key('share-error'))
                else ...[
                  SelectableText(
                    share.code ?? '',
                    key: const Key('share-code'),
                    style: textTheme.displaySmall?.copyWith(letterSpacing: 6),
                  ),
                  const SizedBox(height: DartsSpace.md),
                  const Text(
                    'Sur l’autre téléphone : « Rejoindre une session » à '
                    'l’accueil, puis ce code. Il affiche la partie, et '
                    'peut saisir lui aussi.',
                    textAlign: TextAlign.center,
                  ),
                  if (share.joinedCount > 0) ...[
                    const SizedBox(height: DartsSpace.md),
                    Text(
                      share.joinedCount == 1
                          ? '1 appareil a rejoint'
                          : '${share.joinedCount} appareils ont rejoint',
                      key: const Key('share-joined'),
                      style: textTheme.titleMedium,
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            if (failed)
              TextButton(
                onPressed: () =>
                    setState(() => _started = widget.share.start()),
                child: const Text('Réessayer'),
              )
            else if (!waiting && widget.canStop)
              TextButton(
                onPressed: () {
                  share.stop();
                  Navigator.of(context).pop();
                },
                child: const Text('Arrêter le partage'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}

/// Asks for the code of a shared session and has [join] join it. Says
/// whether it was joined; false when the user backed out.
Future<bool> showJoinDialog(
  BuildContext context,
  Future<void> Function(String code) join,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _JoinDialog(join: join),
    ) ??
    false;

class _JoinDialog extends StatefulWidget {
  const _JoinDialog({required this.join});

  final Future<void> Function(String code) join;

  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final _code = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await widget.join(_code.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = error is ShareUnreachable
            ? _unreachable
            : 'Aucune session partagée sous ce code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _code.text.length == SessionShare.codeLength;
    return AlertDialog(
      title: const Text('Rejoindre une session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Le code s’affiche sur le téléphone qui partage la session : '
            'l’icône de partage, en haut de la partie.',
          ),
          const SizedBox(height: DartsSpace.md),
          TextField(
            key: const Key('join-code'),
            controller: _code,
            autofocus: true,
            enabled: !_joining,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(SessionShare.codeLength),
            ],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(letterSpacing: 6),
            decoration: InputDecoration(labelText: 'Code', errorText: _error),
            onSubmitted: (_) {
              if (complete) _join();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _joining ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: complete && !_joining ? _join : null,
          child: _joining
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Rejoindre'),
        ),
      ],
    );
  }
}
