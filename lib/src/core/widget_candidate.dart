import 'package:flutter/widgets.dart';
import 'grab_result.dart';

/// Represents a candidate widget discovered during RenderObject hit testing.
///
/// Separates the physical hit location and render object from the metadata
/// resolution (which is provided on-demand via [WidgetInspectorBridge]).
class WidgetCandidate {
  WidgetCandidate({
    required this.element,
    required this.renderBox,
    required this.bounds,
    this.depth = 0,
    GrabResult? result,
  }) : _result = result;

  /// The live Element in the Flutter tree.
  final Element element;

  /// The RenderBox associated with this element or its nearest render object.
  final RenderBox? renderBox;

  /// Global screen bounding box of the widget.
  final Rect? bounds;

  /// Depth in the widget hierarchy (leaf = 0, ancestors > 0).
  final int depth;

  GrabResult? _result;

  /// The resolved diagnostic / location context.
  GrabResult? get result => _result;

  /// Attaches resolved source metadata to this candidate.
  void attachResult(GrabResult result) {
    _result = result;
  }

  String get widgetName => _result?.widgetName ?? element.widget.runtimeType.toString();
  String? get filePath => _result?.filePath;
  int? get line => _result?.line;
  int? get column => _result?.column;
  bool get isLocalProject => _result?.isLocalProject ?? false;

  @override
  String toString() => 'WidgetCandidate($widgetName @ ${bounds?.size})';
}
