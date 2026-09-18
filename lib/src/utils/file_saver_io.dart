import 'dart:io';
import 'package:flutter/foundation.dart';

/// Saves screenshot bytes to the local filesystem for AI inspection.
String? saveScreenshotFile(String widgetName, Uint8List bytes) {
  try {
    final cleanName = widgetName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = '$cleanName.png';

    // Try /tmp/flutter_grab first (cleanest direct path for macOS and Linux)
    try {
      final tmpDir = Directory('/tmp/flutter_grab');
      if (!tmpDir.existsSync()) {
        tmpDir.createSync(recursive: true);
      }
      final file = File('${tmpDir.path}/$fileName');
      file.writeAsBytesSync(bytes);
      return file.path;
    } catch (_) {
      // Fallback to system temp directory (safe for iOS sandbox, Android, Windows)
      final sysDir = Directory('${Directory.systemTemp.path}/flutter_grab');
      if (!sysDir.existsSync()) {
        sysDir.createSync(recursive: true);
      }
      final file = File('${sysDir.path}/$fileName');
      file.writeAsBytesSync(bytes);
      return file.path;
    }
  } catch (e) {
    debugPrint('[Flutter Grab] Failed to save screenshot to disk: $e');
    return null;
  }
}
