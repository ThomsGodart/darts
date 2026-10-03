import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/darts_space.dart';
import '../app_version.dart';

/// Stub settings: privacy policy (asset) and app version. No accounts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.privacyAsset = 'assets/privacy_fr.txt',
  });

  final String privacyAsset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(DartsSpace.lg),
        children: [
          Text('Version', style: textTheme.titleLarge),
          const SizedBox(height: DartsSpace.xs),
          Text(
            appVersionName,
            key: const Key('app-version'),
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: DartsSpace.xl),
          Text('Confidentialité', style: textTheme.titleLarge),
          const SizedBox(height: DartsSpace.sm),
          FutureBuilder<String>(
            future: rootBundle.loadString(privacyAsset),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Impossible de charger la politique de confidentialité.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Text(
                snapshot.data!,
                key: const Key('privacy-policy'),
                style: textTheme.bodyMedium,
              );
            },
          ),
        ],
      ),
    );
  }
}
