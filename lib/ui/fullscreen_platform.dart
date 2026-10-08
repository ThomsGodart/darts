export 'fullscreen_platform_stub.dart'
    if (dart.library.io) 'fullscreen_platform_io.dart'
    if (dart.library.js_interop) 'fullscreen_platform_web.dart';
