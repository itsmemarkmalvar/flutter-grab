#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const args = process.argv.slice(2);
const command = args[0] || 'init';

const cyan = '\x1b[36m';
const green = '\x1b[32m';
const yellow = '\x1b[33m';
const red = '\x1b[31m';
const reset = '\x1b[0m';
const bold = '\x1b[1m';

function printBanner() {
  console.log(`${cyan}${bold}`);
  console.log('====================================================');
  console.log('            🎯 Flutter Grab Installer               ');
  console.log('====================================================');
  console.log(reset);
}

const cwd = process.cwd();
const pubspecPath = path.join(cwd, 'pubspec.yaml');
const mainDartPath = path.join(cwd, 'lib', 'main.dart');

if (command === 'init') {
  printBanner();

  if (!fs.existsSync(pubspecPath)) {
    console.error(`${red}❌ Error: No pubspec.yaml found in ${cwd}.${reset}`);
    console.error('Please run this command from the root directory of your Flutter project.');
    process.exit(1);
  }

  if (!fs.existsSync(mainDartPath)) {
    console.error(`${red}❌ Error: No lib/main.dart found in ${cwd}.${reset}`);
    process.exit(1);
  }

  // 1. Add dependency to pubspec.yaml
  console.log('📦 Checking pubspec.yaml...');
  let pubspec = fs.readFileSync(pubspecPath, 'utf8');
  if (!pubspec.includes('flutter_grab:')) {
    console.log('➕ Adding flutter_grab to dev_dependencies...');
    if (pubspec.includes('dev_dependencies:')) {
      pubspec = pubspec.replace('dev_dependencies:', 'dev_dependencies:\n  flutter_grab: ^0.2.0');
    } else {
      pubspec += '\ndev_dependencies:\n  flutter_grab: ^0.2.0\n';
    }
    fs.writeFileSync(pubspecPath, pubspec, 'utf8');
    console.log(`${green}✔ Added flutter_grab to dev_dependencies${reset}`);
  } else {
    console.log(`${green}✔ flutter_grab already present in pubspec.yaml${reset}`);
  }

  // 2. Configure lib/main.dart
  console.log('⚙️  Configuring lib/main.dart...');
  let mainContent = fs.readFileSync(mainDartPath, 'utf8');
  const importStatement = "import 'package:flutter_grab/flutter_grab.dart';";

  if (!mainContent.includes(importStatement)) {
    mainContent = `${importStatement}\n${mainContent}`;
    console.log(`${green}✔ Injected import into lib/main.dart${reset}`);
  }

  if (mainContent.includes('FlutterGrab.builder') || mainContent.includes('FlutterGrab.chain') || mainContent.includes('FlutterGrab(')) {
    console.log(`${yellow}ℹ FlutterGrab is already configured in lib/main.dart${reset}`);
  } else {
    const appMatch = mainContent.match(/(MaterialApp|CupertinoApp)\s*\(/);
    if (appMatch) {
      const appType = appMatch[1];
      const existingBuilderMatch = mainContent.match(/builder:\s*([^,\n\)]+)/);
      if (existingBuilderMatch) {
        const existingBuilder = existingBuilderMatch[1].trim();
        mainContent = mainContent.replace(
          existingBuilderMatch[0],
          `builder: FlutterGrab.chain(${existingBuilder})`
        );
        console.log(`${green}✔ Chained FlutterGrab with existing builder in ${appType}${reset}`);
      } else {
        mainContent = mainContent.replace(
          `${appType}(`,
          `${appType}(\n      builder: FlutterGrab.builder,`
        );
        console.log(`${green}✔ Injected builder: FlutterGrab.builder into ${appType}${reset}`);
      }
    } else {
      mainContent = mainContent.replace(
        /runApp\s*\(([^;]+)\);/,
        'runApp(FlutterGrab(child: $1));'
      );
      console.log(`${green}✔ Wrapped runApp with FlutterGrab${reset}`);
    }
    fs.writeFileSync(mainDartPath, mainContent, 'utf8');
  }

  // 3. Run flutter pub get
  console.log('🚀 Running flutter pub get...');
  const pubResult = spawnSync('flutter', ['pub', 'get'], { stdio: 'inherit' });

  console.log(`\n${green}${bold}====================================================`);
  console.log('  🎉 Flutter Grab is successfully installed!');
  console.log(`====================================================${reset}`);
  console.log('To start grabbing widgets:\n');
  console.log(`  1. Run your app: ${yellow}flutter run${reset}`);
  console.log(`  2. Press ${yellow}Cmd + Shift + C${reset} (or tap the floating Grab pill)`);
  console.log('  3. Click any widget and copy its context for your AI assistant!\n');

} else if (command === 'remove' || command === 'uninstall') {
  if (!fs.existsSync(mainDartPath)) {
    console.error(`${red}❌ Error: No lib/main.dart found.${reset}`);
    process.exit(1);
  }

  let mainContent = fs.readFileSync(mainDartPath, 'utf8');
  mainContent = mainContent.replace("import 'package:flutter_grab/flutter_grab.dart';\n", '');
  mainContent = mainContent.replace("import 'package:flutter_grab/flutter_grab.dart';", '');
  mainContent = mainContent.replace(/\s*builder:\s*FlutterGrab\.builder,?\n?/g, '');
  mainContent = mainContent.replace(/builder:\s*FlutterGrab\.chain\(([^)]+)\)/g, 'builder: $1');
  mainContent = mainContent.replace(/runApp\s*\(\s*FlutterGrab\s*\(\s*child:\s*([^)]+)\)\);/g, 'runApp($1);');

  fs.writeFileSync(mainDartPath, mainContent, 'utf8');
  console.log(`${green}✔ Removed FlutterGrab configuration from lib/main.dart${reset}`);

} else {
  console.log(`Usage: npx flutter-grab [init|remove]`);
}
