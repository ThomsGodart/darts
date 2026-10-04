import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/darts_space.dart';
import '../app_version.dart';
import 'app_settings.dart';

/// The app's settings, its version and its privacy policy. No accounts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    this.privacyAsset = 'assets/privacy_fr.txt',
  });

  final AppSettings settings;
  final String privacyAsset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(DartsSpace.lg),
        children: [
          Text('Écran de jeu', style: textTheme.titleLarge),
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) => SwitchListTile(
              key: const Key('portrait-lock'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Verrouiller en portrait'),
              subtitle: const Text(
                'L’écran de jeu ne passe plus en paysage quand le '
                'téléphone tourne',
              ),
              value: settings.portraitLock,
              onChanged: settings.setPortraitLock,
            ),
          ),
          const SizedBox(height: DartsSpace.xl),
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
