import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'soiree/soiree.dart';
import 'soiree_launcher.dart';
import 'theme/app_themes.dart';

class DartsApp extends StatelessWidget {
  const DartsApp({
    super.key,
    required this.repository,
    this.themeId = defaultThemeId,
  });

  /// Where soirées are kept: the device database, or memory in tests.
  final SoireeRepository repository;
  final String themeId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darts',
      debugShowCheckedModeBanner: false,
      theme: themeById(themeId),
      home: HomeScreen(launcher: SoireeLauncher(repository)),
    );
  }
}
