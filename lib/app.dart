import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'soiree_controller.dart';
import 'theme/app_themes.dart';

class DartsApp extends StatelessWidget {
  const DartsApp({
    super.key,
    this.themeId = defaultThemeId,
    this.newSoiree = SoireeController.inMemory,
  });

  final String themeId;

  /// Composition root for the domain: how a new soirée is created.
  final SoireeController Function() newSoiree;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darts',
      debugShowCheckedModeBanner: false,
      theme: themeById(themeId),
      home: HomeScreen(newSoiree: newSoiree),
    );
  }
}
