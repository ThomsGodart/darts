import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
              // The pane is laid out at the width that, once scaled,
              // makes it as tall as the screen: a short pad gets taller
              // keys, a long one gets smaller rather than scrolling.
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: FittedBox(
                  child: _PaneFit(
                    pane: Size(paneWidth, constraints.maxHeight),
                    child: input,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Lays its child out at the width whose height has the proportions of
/// [pane], so that scaling it to the pane fills it both ways. Within
/// limits: a pane with next to nothing in it is not blown up to fit.
class _PaneFit extends SingleChildRenderObjectWidget {
  const _PaneFit({required this.pane, required super.child});

  final Size pane;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPaneFit(pane);

  @override
  void updateRenderObject(BuildContext context, _RenderPaneFit renderObject) =>
      renderObject.pane = pane;
}

class _RenderPaneFit extends RenderProxyBox {
  _RenderPaneFit(this._pane);

  /// How much narrower or wider than the pane the child may be laid out,
  /// that is how much it may end up scaled.
  static const _narrowest = 0.6;
  static const _widest = 1.8;

  Size _pane;
  set pane(Size value) {
    if (value == _pane) return;
    _pane = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    var width = _pane.width;
    // The height hardly depends on the width: a few rounds settle it.
    for (var round = 0; round < 4; round++) {
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      final wanted = (_pane.width * child.size.height / _pane.height).clamp(
        _pane.width * _narrowest,
        _pane.width * _widest,
      );
      if ((wanted - width).abs() < 1) break;
      width = wanted;
    }
    size = child.size;
  }
}
