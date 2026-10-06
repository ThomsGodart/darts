import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'session/session.dart';
import 'session_launcher.dart';
import 'settings/app_settings.dart';
import 'share/share_transport.dart';
import 'theme/app_themes.dart';

class DartsApp extends StatefulWidget {
  const DartsApp({
    super.key,
    required this.repository,
    required this.catalog,
    this.settingsStore,
    this.shareTransport,
    this.themeId = defaultThemeId,
  });

  /// Where sessions are kept: the device database, or memory in tests.
  final SessionRepository repository;

  /// The players known to the app.
  final PlayerCatalog catalog;

  /// Where settings are kept; in memory when not given.
  final SettingsStore? settingsStore;

  /// What sessions are shared over with other devices; without it the
  /// app does not offer to share or join one.
  final ShareTransport? shareTransport;
  final String themeId;

  @override
  State<DartsApp> createState() => _DartsAppState();
}

class _DartsAppState extends State<DartsApp> {
  /// One launcher for the life of the app: the repository reports storage
  /// failures to a single watcher.
  late final SessionLauncher _launcher = SessionLauncher(
    widget.repository,
    widget.catalog,
  );

  late final AppSettings _settings = AppSettings(
    widget.settingsStore ?? InMemorySettingsStore(),
  );

  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  @override
  void dispose() {
    _settings.dispose();
    _launcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darts',
      debugShowCheckedModeBanner: false,
      theme: themeById(widget.themeId),
      home: HomeScreen(
        launcher: _launcher,
        settings: _settings,
        shareTransport: widget.shareTransport,
      ),
    );
  }
}
