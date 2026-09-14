import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/grab_result.dart';

/// Bridge to Flutter's [WidgetInspectorService] and widget diagnostic metadata.
class WidgetInspectorBridge {
  const WidgetInspectorBridge();

  static const String _inspectorGroup = 'flutter_grab_inspector';

  /// Resolves the diagnostic location and metadata for a given [element].
  GrabResult resolveElement(Element element) {
    final widgetName = element.widget.runtimeType.toString();
    final bounds = _extractBounds(element);

    if (!kDebugMode) {
      return GrabResult(
        widgetName: widgetName,
        bounds: bounds,
      );
    }

    String? filePath;
    int? line;
    int? column;
    bool isLocal = false;

    try {
      final inspector = WidgetInspectorService.instance;
      inspector.selection.currentElement = element;
      final ro = element.findRenderObject();
      if (ro != null) {
        inspector.selection.current = ro;
      }

      final summaryJson = inspector.getSelectedSummaryWidget(null, _inspectorGroup);
      if (summaryJson.isNotEmpty) {
        final data = jsonDecode(summaryJson) as Map<String, dynamic>;
        isLocal = data['createdByLocalProject'] == true;

        final loc = data['creationLocation'] as Map<String, dynamic>?;
        if (loc != null) {
          filePath = _normalizeFilePath(loc['file'] as String?);
          line = loc['line'] as int?;
          column = loc['column'] as int?;
        }
      }
    } catch (_) {
      // Fallback if inspector service fails or is unavailable
    }

    // Build ancestry chain
    final ancestry = _extractAncestry(element);

    return GrabResult(
      widgetName: widgetName,
      filePath: filePath,
      line: line,
      column: column,
      isLocalProject: isLocal,
      ancestry: ancestry,
      bounds: bounds,
    );
  }

  /// Extracts the global screen [Rect] for an [element].
  Rect? _extractBounds(Element element) {
    try {
      final ro = element.findRenderObject();
      if (ro is RenderBox && ro.hasSize && ro.attached) {
        final translation = ro.getTransformTo(null).getTranslation();
        return Offset(translation.x, translation.y) & ro.size;
      }
    } catch (_) {}
    return null;
  }

  static const Set<String> _ignoredAncestors = {
    'Focus', 'FocusScope', 'FocusTraversalGroup', 'Semantics', 'Shortcuts', 'Actions', 'Builder',
    'KeyedSubtree', 'RestorationScope', 'UnmanagedRestorationScope',
    'RootRestorationScope', 'SharedAppData', 'NotificationListener',
    'ListenableBuilder', 'ValueListenableBuilder', 'AnimatedBuilder',
    'SlideTransition', 'FractionalTranslation', 'FadeTransition',
    'DualTransitionBuilder', 'DecoratedBoxTransition', 'CupertinoPageTransition',
    'IgnorePointer', 'AbsorbPointer', 'RepaintBoundary', 'TickerMode', 'PageStorage',
    'Offstage', 'TapRegionSurface', 'ShortcutRegistrar',
    'PrimaryScrollController', 'ScrollNotificationObserver',
    'DefaultSelectionStyle', 'DefaultTextStyle', 'AnimatedDefaultTextStyle',
    'IconTheme', 'Theme', 'AnimatedTheme', 'CupertinoTheme',
    'InheritedCupertinoTheme', 'Directionality', 'Title', 'Localizations',
    'HeroControllerScope', 'ScrollConfiguration', 'CustomMultiChildLayout',
    'LayoutId', 'RawGestureDetector', 'Listener', 'MediaQuery',
    'WidgetsApp', 'RootWidget', 'View', 'RawView', 'MaterialApp',
    'ScaffoldMessenger', 'Scrollable', 'Navigator', 'Overlay',
    'PhysicalModel', 'AnimatedPhysicalModel', 'Material', 'DecoratedBox', 'Stack',
  };

  /// Builds a clean ancestry breadcrumb list for [element].
  List<String> _extractAncestry(Element element) {
    final ancestors = <String>[];
    element.visitAncestorElements((ancestor) {
      final name = ancestor.widget.runtimeType.toString();

      // Stop walking when reaching the FlutterGrab boundary
      if (name.startsWith('FlutterGrab') || name.startsWith('Grab')) {
        return false;
      }

      // Skip private framework widgets and plumbing wrappers
      if (name.startsWith('_') ||
          _ignoredAncestors.contains(name) ||
          name.startsWith('NotificationListener<') ||
          name.startsWith('ValueListenableBuilder<') ||
          name.startsWith('Inherited')) {
        return true;
      }

      // Deduplicate consecutive identical names
      if (ancestors.isEmpty || ancestors.last != name) {
        ancestors.add(name);
      }
      return true;
    });

    // Reverse so it reads from Root -> Parent -> Target
    return ancestors.reversed.toList();
  }

  /// Cleans and normalizes the source file path (e.g., converts file:/// to relative path).
  String? _normalizeFilePath(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    var path = raw;
    if (path.startsWith('file://')) {
      path = path.replaceFirst('file://', '');
    }

    // Try to trim common project prefixes to make it readable: e.g. "lib/..."
    final libIndex = path.indexOf('/lib/');
    if (libIndex != -1) {
      return path.substring(libIndex + 1); // e.g. "lib/main.dart"
    }

    final testIndex = path.indexOf('/test/');
    if (testIndex != -1) {
      return path.substring(testIndex + 1); // e.g. "test/widget_test.dart"
    }

    return path;
  }
}
