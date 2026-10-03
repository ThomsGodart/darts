import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          Text('Version', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            appVersionName,
            key: const Key('app-version'),
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Confidentialité', style: textTheme.titleLarge),
          const SizedBox(height: 8),
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
