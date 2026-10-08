import 'package:flutter/material.dart';

import 'app_fullscreen.dart';

/// Toggles in-app fullscreen; hidden when the platform cannot do it.
class FullscreenButton extends StatelessWidget {
  const FullscreenButton({super.key, required this.fullscreen});

  final AppFullscreen fullscreen;

  @override
  Widget build(BuildContext context) {
    if (!fullscreen.isSupported) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: fullscreen,
      builder: (context, _) => IconButton(
        key: const Key('toggle-fullscreen'),
        tooltip: fullscreen.isActive
            ? 'Quitter le plein écran'
            : 'Plein écran',
        icon: Icon(
          fullscreen.isActive
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
        ),
        onPressed: fullscreen.toggle,
      ),
    );
  }
}
