import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/widget_candidate.dart';

/// Pure Flutter hit tester that resolves screen coordinates to [RenderObject]s and [Element]s.
///
/// Follows the pipeline:
/// Pointer (x, y) ➔ RenderView / RenderObject hit testing ➔ RenderObject ➔ Element ➔ WidgetCandidate
class HitTester {
  const HitTester();

  /// Inspects widgets at the given global screen [position] using standard Flutter hit-testing.
  ///
  /// If [rootRenderBox] is provided, hit testing is scoped directly to the app content,
  /// completely bypassing any overlay widgets (e.g. FlutterGrab's own HUD / Listener).
  ///
  /// Returns a list of [WidgetCandidate] ordered from the deepest leaf up to ancestors.
  List<WidgetCandidate> hitTest(
    Offset position, {
    int? viewId,
    RenderBox? rootRenderBox,
  }) {
    if (!kDebugMode) return const [];

    final List<HitTestEntry> hitEntries;

    if (rootRenderBox != null && rootRenderBox.hasSize && rootRenderBox.attached) {
      final localPosition = rootRenderBox.globalToLocal(position);
      final boxHitTestResult = BoxHitTestResult();
      rootRenderBox.hitTest(boxHitTestResult, position: localPosition);
      hitEntries = boxHitTestResult.path.toList();
    } else {
      final hitTestResult = HitTestResult();
      final effectiveViewId = viewId ??
          WidgetsBinding.instance.platformDispatcher.implicitView?.viewId ??
          0;

      try {
        WidgetsBinding.instance.hitTestInView(hitTestResult, position, effectiveViewId);
        hitEntries = hitTestResult.path.toList();
      } catch (_) {
        return const [];
      }
    }

    final visitedElements = <Element>{};
    final candidates = <WidgetCandidate>[];

    for (final entry in hitEntries) {
      final target = entry.target;
      if (target is! RenderObject) continue;

      final creator = target.debugCreator;
      if (creator is! DebugCreator) continue;

      final element = creator.element;
      _collectElementAndAncestors(element, visitedElements, candidates);
    }

    return candidates;
  }

  void _collectElementAndAncestors(
    Element leafElement,
    Set<Element> visited,
    List<WidgetCandidate> candidates,
  ) {
    var depth = 0;

    bool isInternalGrabWidget(String name) {
      return name.startsWith('FlutterGrab') ||
          name.startsWith('Grab') ||
          name.startsWith('FloatingTrigger') ||
          name.startsWith('HighlightPainter');
    }

    void addElement(Element element) {
      if (visited.contains(element)) return;
      visited.add(element);

      final widgetName = element.widget.runtimeType.toString();
      // Skip private framework widgets and flutter_grab internal overlay widgets
      if (widgetName.startsWith('_')) return;
      if (isInternalGrabWidget(widgetName)) return;

      final bounds = _extractBounds(element);
      final ro = element.findRenderObject();
      final renderBox = ro is RenderBox ? ro : null;

      if (bounds != null && bounds.width > 0 && bounds.height > 0) {
        candidates.add(
          WidgetCandidate(
            element: element,
            renderBox: renderBox,
            bounds: bounds,
            depth: depth,
          ),
        );
        depth++;
      }
    }

    // Add leaf element
    addElement(leafElement);

    // Walk up ancestors
    leafElement.visitAncestorElements((ancestor) {
      final ancestorName = ancestor.widget.runtimeType.toString();
      // Stop walking when reaching the FlutterGrab boundary
      if (isInternalGrabWidget(ancestorName)) {
        return false;
      }
      addElement(ancestor);
      return true;
    });
  }

  /// Extracts the global screen [Rect] for an [element] from its RenderBox.
  static Rect? _extractBounds(Element element) {
    try {
      final ro = element.findRenderObject();
      if (ro is RenderBox && ro.hasSize && ro.attached) {
        final translation = ro.getTransformTo(null).getTranslation();
        return Offset(translation.x, translation.y) & ro.size;
      }
    } catch (_) {}
    return null;
  }

  static const Set<String> _primitiveWidgets = {
    'DecoratedBox', 'ColoredBox', 'Padding', 'Align', 'Center',
    'SizedBox', 'ConstrainedBox', 'FractionallySizedBox', 'FittedBox',
    'RichText', 'RawImage', 'ClipRect', 'ClipRRect', 'CustomPaint',
    'Transform', 'Opacity', 'Positioned', 'Expanded', 'Flexible',
    'PhysicalModel', 'PhysicalShape', 'Container',
    'GestureDetector', 'RawGestureDetector', 'InkWell', 'InkResponse', 'MouseRegion',
  };

  /// Picks the most relevant candidate among [candidates].
  ///
  /// Prioritizes composite / custom components (e.g. DashboardHeader, MetricCard, Text, ElevatedButton)
  /// over internal rendering primitives (e.g. DecoratedBox, Padding).
  static WidgetCandidate? findBestCandidate(List<WidgetCandidate> candidates) {
    if (candidates.isEmpty) return null;

    // 1. Prefer custom composite widgets (StatelessWidget or StatefulWidget)
    for (final c in candidates) {
      final widget = c.element.widget;
      final name = c.widgetName;
      if (!_primitiveWidgets.contains(name) &&
          (widget is StatelessWidget || widget is StatefulWidget)) {
        return c;
      }
    }

    // 2. Fall back to the leaf widget
    return candidates.first;
  }
}
