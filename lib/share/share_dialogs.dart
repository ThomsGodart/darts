import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../session/session.dart';
import '../session_launcher.dart';
import '../theme/darts_space.dart';
import 'session_share.dart';
import 'share_transport.dart';

const _unreachable = 'Connexion impossible. Vérifiez le réseau.';
const _incompatible =
    'Un des téléphones utilise une autre version de l’application : '
    'mettez-la à jour sur les deux.';

/// Shows the code of [share] and how it goes; on the device that shares,
/// puts the session on the line first when it is not, and offers to take
/// it off again or to keep the input to itself.
Future<void> showShareDialog(BuildContext context, SessionShare share) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ShareDialog(share: share),
    );

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.share});

  final SessionShare share;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  late Future<void> _started = _start();

  /// A guest is on the line from joining.
  Future<void> _start() =>
      widget.share.isGuest ? Future.value() : widget.share.start();

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
                  Text(
                    share.inputLocked
                        ? 'Sur l’autre téléphone : « Rejoindre une session » '
                              'à l’accueil, puis ce code. Il affiche la '
                              'partie.'
                        : 'Sur l’autre téléphone : « Rejoindre une session » '
                              'à l’accueil, puis ce code. Il affiche la '
                              'partie, et peut saisir lui aussi.',
                    textAlign: TextAlign.center,
                  ),
                  if (share.isOffLine) ...[
                    const SizedBox(height: DartsSpace.md),
                    Text(
                      'Connexion perdue : elle reprend dès que le réseau '
                      'revient.',
                      key: const Key('share-lost'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (share.hasIncompatiblePeer) ...[
                    const SizedBox(height: DartsSpace.md),
                    const Text(
                      _incompatible,
                      key: Key('share-incompatible'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!share.isGuest)
                    SwitchListTile(
                      key: const Key('share-lock-input'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Saisie sur ce téléphone seulement'),
                      subtitle: const Text(
                        'Les autres téléphones ne font qu’afficher.',
                      ),
                      value: share.inputLocked,
                      onChanged: share.lockInput,
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
                onPressed: () => setState(() => _started = _start()),
                child: const Text('Réessayer'),
              )
            else if (!waiting && !share.isGuest)
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

/// Asks for the code of a shared session and has [join] join it. Gives
/// the share that was joined; null when the user backed out.
Future<SessionShare?> showJoinDialog(
  BuildContext context,
  Future<SessionShare> Function(String code) join,
) => showDialog<SessionShare>(
  context: context,
  builder: (_) => _JoinDialog(join: join),
);

class _JoinDialog extends StatefulWidget {
  const _JoinDialog({required this.join});

  final Future<SessionShare> Function(String code) join;

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
      final share = await widget.join(_code.text);
      if (mounted) {
        Navigator.of(context).pop(share);
      } else {
        share.dispose();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = switch (error) {
          ShareUnreachable() => _unreachable,
          IncompatibleShare() => _incompatible,
          _ => 'Aucune session partagée sous ce code.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _code.text.length == SessionShare.codeLength;
    return PopScope(
      // Not while joining: the share would be made with nobody to take it.
      canPop: !_joining,
      child: AlertDialog(
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
              decoration: InputDecoration(
                labelText: 'Code',
                errorText: _error,
                errorMaxLines: 3,
              ),
              onSubmitted: (_) {
                if (complete) _join();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _joining ? null : () => Navigator.of(context).pop(),
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
      ),
    );
  }
}

/// Asks whether to keep a joined session on this device, and who its
/// people are here. Gives, by the id each has in the session, the known
/// player they are — those left out being new players; null when the
/// session is not to be kept.
Future<Map<String, Player>?> showKeepDialog(
  BuildContext context,
  KeepProposal proposal,
) => showDialog<Map<String, Player>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _KeepDialog(proposal: proposal),
);

class _KeepDialog extends StatefulWidget {
  const _KeepDialog({required this.proposal});

  final KeepProposal proposal;

  @override
  State<_KeepDialog> createState() => _KeepDialogState();
}

class _KeepDialogState extends State<_KeepDialog> {
  /// Who each person is here, by their id in the session; absent for a
  /// new player.
  late final Map<String, Player> _who = {
    for (final (:shared, :match) in widget.proposal.people) shared.id: ?match,
  };

  /// Whether two people were said to be the same player.
  bool get _clashes =>
      _who.values.map((p) => p.id).toSet().length != _who.length;

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Garder cette session ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elle s’ajoute à l’historique et aux statistiques de ce '
              'téléphone. Qui est qui ?',
            ),
            const SizedBox(height: DartsSpace.sm),
            for (final (:shared, match: _) in proposal.people)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shared.name,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: DartsSpace.sm),
                  DropdownButton<Player?>(
                    key: Key('keep-as-${shared.id}'),
                    value: _who[shared.id],
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Nouveau joueur'),
                      ),
                      for (final player in proposal.known)
                        DropdownMenuItem(
                          value: player,
                          child: Text(player.name),
                        ),
                    ],
                    onChanged: (player) => setState(
                      () => player == null
                          ? _who.remove(shared.id)
                          : _who[shared.id] = player,
                    ),
                  ),
                ],
              ),
            if (_clashes)
              Padding(
                padding: const EdgeInsets.only(top: DartsSpace.sm),
                child: Text(
                  'Deux personnes ne peuvent pas être le même joueur.',
                  key: const Key('keep-clash'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (proposal.endsOpenSession)
              const Padding(
                padding: EdgeInsets.only(top: DartsSpace.sm),
                child: Text(
                  'La session en cours sur ce téléphone sera terminée : '
                  'elle passe dans l’historique.',
                  key: Key('keep-ends-open'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ne pas garder'),
        ),
        FilledButton(
          onPressed: _clashes ? null : () => Navigator.of(context).pop(_who),
          child: const Text('Garder'),
        ),
      ],
    );
  }
}
