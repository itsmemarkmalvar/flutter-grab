# 🎯 flutter_grab

[![pub package](https://img.shields.io/badge/pub-v0.1.0-blue.svg)](https://pub.dev)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Flutter Grab** is a development-only productivity tool for Flutter applications—inspired by `react-grab` and `react-native-grab`—designed to eliminate the **"search tax"** when using AI coding assistants (like **Cursor**, **Claude Code**, **Antigravity**, or **GitHub Copilot**).

Instead of hunting through deeply nested widget trees to find which `.dart` file and line renders a specific UI element, simply **point, click, and grab**!

---

## ✨ Features

- 🔍 **Visual Element Inspection:** Tap or hover over any widget on-screen to reveal its bounding box, dimensions, and widget type.
- 📍 **Source Code Location:** Extracts the exact source file path, line number, and column number directly via Flutter's debug `--track-widget-creation` instrumentation.
- 🎯 **Smart "User Code" Detection:** Distinguishes your project's custom widgets from Flutter internal widgets (`Padding`, `Semantics`, `Directionality`).
- 🍞 **Interactive Breadcrumbs:** Inspect the widget ancestor hierarchy and jump between leaf widgets and parent containers.
- 📋 **AI-Ready Prompt Output:** Formats the captured context into clean Markdown or XML snippets ready to paste directly into your AI prompt.
- ⌨️ **Desktop & Web Shortcuts:** Toggle Grab mode with `Cmd+Shift+C` (macOS) or `Ctrl+Shift+C` (Windows/Linux).
- 📱 **Mobile-Friendly:** Draggable floating action pill designed for single-handed touch interactions on simulators and physical devices.
- 🛡️ **Zero Release Overhead:** Completely inert and no-op in `release` and `profile` builds (`kDebugMode` guarded). 0% runtime penalty or binary leakage in production.

---

## 🚀 Quick Install (1-Command Setup)

Just like `npx grab init` or the AG Kit, your users can install Flutter Grab into any existing Flutter project with a single command:

```bash
npx flutter-grab init
```

*(Or for pure Dart developers without Node installed: `dart run flutter_grab:init`)*

This automatically:
1. Adds `flutter_grab` to `dev_dependencies` in `pubspec.yaml`.
2. Injects `import 'package:flutter_grab/flutter_grab.dart';` into `lib/main.dart`.
3. Injects `builder: FlutterGrab.builder` (or chains with any existing builder).
4. Runs `flutter pub get`.

To uninstall anytime:
```bash
npx flutter-grab remove
```

---

## 🛠️ Manual Installation (Alternative)

If you prefer to configure it manually:

### 1. Add Dependency

Add `flutter_grab` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_grab: ^0.1.0
```

### 2. Wrap Your App

Add `builder: FlutterGrab.builder` in your `MaterialApp` or `CupertinoApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_grab/flutter_grab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      // Simply add FlutterGrab.builder here:
      builder: FlutterGrab.builder,
      home: const HomeScreen(),
    );
  }
}
```

*Or if you already have an existing custom builder in your app:*

```dart
MaterialApp(
  builder: FlutterGrab.chain(myExistingBuilder),
  home: const HomeScreen(),
)
```

---

## 💡 How to Use

1. **Activate Grab Mode:**
   - Tap the floating **Grab** pill on your screen, or
   - Press **`Cmd + Shift + C`** (Mac) / **`Ctrl + Shift + C`** (Windows/Linux).
2. **Select Any Widget:**
   - Move your mouse or drag your finger over widgets. A real-time bounding box highlights the candidate widget.
   - Tap/click to lock the selection.
3. **Grab Context:**
   - Tap **"Grab Context"** (or press the copy button) on the HUD.
   - The AI context snippet is copied to your clipboard with haptic feedback!
4. **Paste into your AI Agent (Cursor / Claude / Copilot):**

```markdown
<!-- Flutter Grab Context -->
### Target Widget: `DashboardHeader`
- **File:** `lib/screens/dashboard_screen.dart:42:10`
- **Ancestry:** `DashboardScreen > SingleChildScrollView > DashboardHeader`
- **Size:** `380.0 x 88.0`
```

Then prompt your AI: *"Make the avatar circular and add a green online status badge on the bottom right."*

---

## ⚙️ Configuration & Customization

```dart
FlutterGrab(
  showFloatingTrigger: true,      // Show/hide floating draggable button
  enableKeyboardShortcut: true,   // Enable Cmd+Shift+C / Ctrl+Shift+C
  controller: myGrabController,   // Custom controller if needed
  child: MyApp(),
)
```

### Prompt Formats Supported:

* **Markdown (Default):**
  ```markdown
  <!-- Flutter Grab Context -->
  ### Target Widget: `MetricCard`
  - **File:** `lib/widgets/metric_card.dart:18:5`
  - **Ancestry:** `HomeScreen > MetricsGrid > MetricCard`
  - **Size:** `160.0 x 110.0`
  ```
* **XML Format:**
  ```xml
  <flutter_grab_context>
    <widget>MetricCard</widget>
    <file>lib/widgets/metric_card.dart</file>
    <line>18</line>
    <column>5</column>
    <ancestry>HomeScreen > MetricsGrid > MetricCard</ancestry>
    <dimensions>160.0 x 110.0</dimensions>
  </flutter_grab_context>
  ```
* **Compact Tag:**
  ```html
  <Widget name="MetricCard" file="lib/widgets/metric_card.dart" line="18" col="5" ancestry="HomeScreen > MetricCard" size="160.0 x 110.0" />
  ```

---

## 🧪 Running the Example

```bash
cd example
flutter run -d macos # or chrome, ios, android
```

---

## 👨‍💻 Author

Created and maintained by **Mark Joseph Malvar** ([@itsmemarkmalvar](https://github.com/itsmemarkmalvar)).

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
