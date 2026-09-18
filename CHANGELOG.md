# Changelog

## 0.2.0
- **📸 Multimodal Widget Screenshot (`Grab + Shot`)**:
  - Tapping **`+ 📸`** (`Shot!`) captures a pixel-perfect, high-DPI Retina PNG snapshot of the selected widget.
  - Automatically writes the cropped PNG file to `/tmp/flutter_grab/<WidgetName>.png` (or device sandbox temp) via pure Dart (`dart:io`), requiring zero rebuilds to inspect visually.
  - Formats AI prompts with a compact `file://` link (`- **📸 Screenshot:** file:///tmp/flutter_grab/<WidgetName>.png`), adding only ~40 tokens instead of 160KB Base64 bloat so multimodal AI models (Claude, GPT-4o, Cursor agent) can inspect visual UI state directly.
  - Direct OS Pasteboard support via `pasteboard` for pasting raw PNG image binary into Figma, Slack, Discord, or image-enabled AI chat inputs.
  - Added live micro-thumbnail visual preview in the HUD title bar when a screenshot is captured.
- **🛡️ Root-Level Release Guard (`!kDebugMode`)**:
  - Hardened `FlutterGrab.builder`, `FlutterGrab.chain`, and `FlutterGrab.build` with root-level compile-time `!kDebugMode` bypass, ensuring all Grab controllers, HUD overlays, and wrappers are completely dead-code tree-shaken in release APKs and production bundles.

## 0.1.5
- **CLI & Installer Updates**: Updated `npx flutter-grab init` and `dart run flutter_grab:init` installer scripts to default to latest `flutter_grab` releases.
- **Documentation & Example App**: Updated package badges, installation guides, and modernized example theme.

## 0.1.4
- **Multi-Grab / Batch Selection**: Select and queue multiple widgets across the screen, then copy a single consolidated context bundle for AI coding assistants.
- **Ultra-Token-Friendly AI Output**: Streamlined prompt formatting reduces AI token consumption by ~68% with compact hierarchy and direct `Widget → file:line:col (WxH)` mapping.
- **Freeform Dragging & PiP Edge Tucking**: Drag the HUD anywhere on screen, or tuck it into a minimal side bezel pill (video-call style) to keep 100% of the screen unobstructed.
- **Responsive 2-Row HUD Layout**: Restructured header and action bars to prevent horizontal overflow on narrow mobile viewports, with a 100% solid opaque background to prevent underlying UI bleed-through.

## 0.1.3
- **Fix**: Removed `Tooltip` from `GrabHud` to prevent `No Overlay widget found` exception when used at the app root level.

## 0.1.2
- **Smart Adaptive HUD Positioning**: `GrabHud` now automatically flips to the top of the screen when inspecting widgets in the lower half of the screen (e.g. `BottomNavigationBar`, FAB, bottom sheets) so it never covers the target element.
- **Manual Flip & Swipe Controls**: Added a header flip button (↕) and vertical swipe gestures to reposition the HUD between top and bottom on demand.
- **Smooth Animations**: Transitions between docking positions use `AnimatedPositioned` with safe area padding.

## 0.1.1
- **Terminal Console Output**: When grabbing a widget, the formatted AI context is now logged via `debugPrint` so developers debugging over wireless networks or external devices can read it directly from their host computer's terminal.
- Added `CHANGELOG.md`.

## 0.1.0
- Initial release of `flutter_grab`.
- Visual widget inspector and context grabber for Flutter apps.
- Auto-extracts widget creation location (`file:line:col`), ancestry, and dimensions.
- Formats context optimized for AI coding assistants (Cursor, Claude, Copilot, Antigravity).
- Mobile & Desktop support (Floating trigger pill, keyboard shortcuts `Cmd+Shift+C` / `Ctrl+Shift+C`).
- Zero overhead in release mode via `!kDebugMode` compile-time tree-shaking.
