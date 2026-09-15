# Changelog

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
