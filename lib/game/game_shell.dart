import 'package:flutter/material.dart';

/// Shared game layout: portrait stacks state over input; landscape / wide
/// splits état | saisie (~50/50).
class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    required this.statePane,
    required this.inputPane,
  });

  final Widget statePane;
  final Widget inputPane;

  /// Landscape, or a wide portrait tablet: use the side-by-side split.
  static bool splits(BoxConstraints constraints) =>
      constraints.maxWidth > constraints.maxHeight ||
      constraints.maxWidth >= 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final state = KeyedSubtree(
          key: const Key('game-shell-state'),
          child: statePane,
        );
        final input = KeyedSubtree(
          key: const Key('game-shell-input'),
          child: inputPane,
        );
        if (!splits(constraints)) {
          return Column(
            children: [
              Expanded(child: state),
              input,
            ],
          );
        }
        final paneWidth = constraints.maxWidth / 2;
        return Row(
          key: const Key('game-shell-landscape'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: state),
            Expanded(
              // Scale the pad to the pane so chips stay tappable without a
              // competing vertical scroll gesture.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(width: paneWidth, child: input),
              ),
            ),
          ],
        );
      },
    );
  }
}
