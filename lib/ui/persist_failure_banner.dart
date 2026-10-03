import 'package:flutter/material.dart';

import '../theme/darts_space.dart';

/// Warns that local storage stopped accepting writes.
class PersistFailureBanner extends StatelessWidget {
  const PersistFailureBanner({super.key});

  static const message =
      'Sauvegarde interrompue — la reprise peut perdre les coups suivants.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('persist-failure-banner'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DartsSpace.lg,
          vertical: DartsSpace.md,
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: DartsSpace.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
