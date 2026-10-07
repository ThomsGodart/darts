import 'package:flutter/material.dart';

import '../share/session_share.dart';
import '../share/share_dialogs.dart';
import '../theme/darts_space.dart';

/// Slim bar over the game: the way back to the menu, what is played,
/// and what the screen is used for. Leaving keeps the session open, to
/// resume from the home screen.
class GameBar extends StatelessWidget {
  const GameBar({
    super.key,
    required this.label,
    this.share,
    this.keyboardHidden,
    this.onKeyboardHidden,
  });

  final String label;

  /// Shares the session with other devices; null hides the option.
  final SessionShare? share;

  /// Whether the input is put away; null when there is none to put away,
  /// or no choice about it.
  final bool? keyboardHidden;
  final ValueChanged<bool>? onKeyboardHidden;

  @override
  Widget build(BuildContext context) {
    final share = this.share;
    final keyboardHidden = this.keyboardHidden;
    return Row(
      children: [
        IconButton(
          key: const Key('leave-game'),
          tooltip: 'Retour au menu',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (keyboardHidden != null)
          IconButton(
            key: const Key('toggle-keyboard'),
            tooltip: keyboardHidden
                ? 'Afficher le clavier'
                : 'Masquer le clavier (mode écran)',
            icon: Icon(
              keyboardHidden
                  ? Icons.keyboard_outlined
                  : Icons.keyboard_hide_outlined,
            ),
            onPressed: () => onKeyboardHidden?.call(!keyboardHidden),
          ),
        if (share != null)
          ListenableBuilder(
            listenable: share,
            builder: (context, _) => IconButton(
              key: const Key('share-session'),
              tooltip: 'Partager la session',
              icon: Icon(switch (share) {
                _ when share.isOffLine => Icons.cloud_off,
                _ when share.isOn => Icons.cast_connected,
                _ => Icons.cast,
              }),
              onPressed: () => showShareDialog(context, share),
            ),
          ),
      ],
    );
  }
}

/// Says, over a shared game, that the network dropped: what shows may be
/// out of date, and what is entered waits for the line to come back.
class ShareOffLineBanner extends StatelessWidget {
  const ShareOffLineBanner({super.key, required this.share});

  final SessionShare share;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: share,
    builder: (context, _) {
      if (!share.isOffLine) return const SizedBox.shrink();
      final colors = Theme.of(context).colorScheme;
      return Container(
        key: const Key('share-off-line'),
        width: double.infinity,
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: DartsSpace.md,
          vertical: DartsSpace.xs,
        ),
        child: Text(
          share.isGuest
              ? 'Connexion perdue : le score peut ne plus être à jour.'
              : 'Connexion perdue : les autres téléphones ne suivent plus.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onErrorContainer),
        ),
      );
    },
  );
}
