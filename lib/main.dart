import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'backend.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: the backend is optional and must never delay startup.
  unawaited(initBackend());
  runApp(const DartsApp());
}
