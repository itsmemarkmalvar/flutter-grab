import 'dart:io';

void main(List<String> args) async {
  final currentDir = Directory.current;
  final mainDartFile = File('${currentDir.path}/lib/main.dart');

  print('\x1B[36m');
  print('====================================================');
  print('          🗑️ Flutter Grab Uninstaller               ');
  print('====================================================');
  print('\x1B[0m');

  if (!mainDartFile.existsSync()) {
    print('\x1B[31m❌ Error: No lib/main.dart found.\x1B[0m');
    exit(1);
  }

  var mainContent = await mainDartFile.readAsString();

  // Remove import
  mainContent = mainContent.replaceAll("import 'package:flutter_grab/flutter_grab.dart';\n", '');
  mainContent = mainContent.replaceAll("import 'package:flutter_grab/flutter_grab.dart';", '');

  // Remove builder: FlutterGrab.builder,
  mainContent = mainContent.replaceAll(RegExp(r'\s*builder:\s*FlutterGrab\.builder,?\n?'), '');

  // Revert FlutterGrab.chain(...)
  mainContent = mainContent.replaceAllMapped(
    RegExp(r'builder:\s*FlutterGrab\.chain\(([^)]+)\)'),
    (match) => 'builder: ${match.group(1)}',
  );

  // Revert runApp(FlutterGrab(child: ...))
  mainContent = mainContent.replaceAllMapped(
    RegExp(r'runApp\s*\(\s*FlutterGrab\s*\(\s*child:\s*([^)]+)\)\);'),
    (match) => 'runApp(${match.group(1)});',
  );

  await mainDartFile.writeAsString(mainContent);
  print('\x1B[32m✔ Removed FlutterGrab configuration from lib/main.dart\x1B[0m');

  print('\n\x1B[32m✔ Flutter Grab uninstalled successfully.\x1B[0m\n');
}
