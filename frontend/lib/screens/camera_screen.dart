export '../platform_helpers/camera_screen_stub.dart'
if (dart.library.js_interop) 'camera_screen_web.dart'
if (dart.library.io) 'camera_screen_native.dart';