import 'dart:io';

void main(List<String> args) async {
  final currentDir = Directory.current;
  final pubspecFile = File('${currentDir.path}/pubspec.yaml');
  final mainDartFile = File('${currentDir.path}/lib/main.dart');

  print('\x1B[36m');
  print('====================================================');
  print('          🎯 Flutter Grab Installer                 ');
  print('====================================================');
  print('\x1B[0m');

  if (!pubspecFile.existsSync()) {
    print('\x1B[31m❌ Error: No pubspec.yaml found in ${currentDir.path}.\x1B[0m');
    print('Please run this command from the root directory of your Flutter project.');
    exit(1);
  }

  if (!mainDartFile.existsSync()) {
    print('\x1B[31m❌ Error: No lib/main.dart found.\x1B[0m');
    exit(1);
  }

  // 1. Check & add dependency in pubspec.yaml
  print('📦 Checking pubspec.yaml...');
  var pubspecContent = await pubspecFile.readAsString();
  if (!pubspecContent.contains('flutter_grab:')) {
    print('➕ Adding flutter_grab to dev_dependencies...');
    if (pubspecContent.contains('dev_dependencies:')) {
      pubspecContent = pubspecContent.replaceFirst(
        'dev_dependencies:',
        'dev_dependencies:\n  flutter_grab: ^0.1.4',
      );
    } else {
      pubspecContent += '\ndev_dependencies:\n  flutter_grab: ^0.1.4\n';
    }
    await pubspecFile.writeAsString(pubspecContent);
    print('\x1B[32m✔ Added flutter_grab to dev_dependencies\x1B[0m');
  } else {
    print('\x1B[32m✔ flutter_grab already present in pubspec.yaml\x1B[0m');
  }

  // 2. Inject into lib/main.dart
  print('⚙️  Configuring lib/main.dart...');
  var mainContent = await mainDartFile.readAsString();

  // Add import if missing
  const importStatement = "import 'package:flutter_grab/flutter_grab.dart';";
  if (!mainContent.contains(importStatement)) {
    mainContent = '$importStatement\n$mainContent';
    print('\x1B[32m✔ Injected import into lib/main.dart\x1B[0m');
  }

  // Inject builder
  if (mainContent.contains('FlutterGrab.builder') || mainContent.contains('FlutterGrab.chain') || mainContent.contains('FlutterGrab(')) {
    print('\x1B[33mℹ FlutterGrab is already configured in lib/main.dart\x1B[0m');
  } else {
    // Check if MaterialApp or CupertinoApp is present
    final materialAppMatch = RegExp(r'(MaterialApp|CupertinoApp)\s*\(').firstMatch(mainContent);
    if (materialAppMatch != null) {
      final appType = materialAppMatch.group(1)!;
      // Check if there is already a builder: in this app
      final existingBuilderMatch = RegExp(r'builder:\s*([^,\n\)]+)').firstMatch(mainContent);
      if (existingBuilderMatch != null) {
        final existingBuilder = existingBuilderMatch.group(1)!.trim();
        mainContent = mainContent.replaceFirst(
          existingBuilderMatch.group(0)!,
          'builder: FlutterGrab.chain($existingBuilder)',
        );
        print('\x1B[32m✔ Chained FlutterGrab with existing builder in $appType\x1B[0m');
      } else {
        mainContent = mainContent.replaceFirst(
          '$appType(',
          '$appType(\n      builder: FlutterGrab.builder,',
        );
        print('\x1B[32m✔ Injected builder: FlutterGrab.builder into $appType\x1B[0m');
      }
    } else {
      // Fallback: wrap runApp
      mainContent = mainContent.replaceFirstMapped(
        RegExp(r'runApp\s*\(([^;]+)\);'),
        (match) => 'runApp(FlutterGrab(child: ${match.group(1)}));',
      );
      print('\x1B[32m✔ Wrapped runApp with FlutterGrab\x1B[0m');
    }

    await mainDartFile.writeAsString(mainContent);
  }

  // 3. Run flutter pub get
  print('🚀 Running flutter pub get...');
  final pubResult = await Process.run('flutter', ['pub', 'get']);
  if (pubResult.exitCode == 0) {
    print('\x1B[32m✔ Dependencies synced successfully.\x1B[0m');
  }

  print('\n\x1B[32m====================================================');
  print('  🎉 Flutter Grab is successfully installed!');
  print('====================================================\x1B[0m');
  print('To start using Flutter Grab:\n');
  print('  1. Run your app: \x1B[33mflutter run\x1B[0m');
  print('  2. Press \x1B[33mCmd + Shift + C\x1B[0m (or tap the floating Grab pill)');
  print('  3. Click any widget and copy its context for your AI assistant!\n');
}
