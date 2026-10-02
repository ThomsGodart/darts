import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'theme/app_themes.dart';

class DartsApp extends StatelessWidget {
  const DartsApp({super.key, this.themeId = defaultThemeId});

  final String themeId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darts',
      debugShowCheckedModeBanner: false,
      theme: themeById(themeId),
      home: const HomeScreen(),
    );
  }
}
