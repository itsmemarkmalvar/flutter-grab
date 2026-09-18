import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// Represents the captured context of an inspected Flutter widget.
class GrabResult {
  const GrabResult({
    required this.widgetName,
    this.filePath,
    this.line,
    this.column,
    this.isLocalProject = false,
    this.ancestry = const [],
    this.bounds,
    this.extraProperties = const {},
    this.screenshotBytes,
    this.screenshotBase64,
    this.screenshotPath,
  });

  /// The runtime type or constructor name of the widget (e.g. "ProfileCard").
  final String widgetName;

  /// The source file path (relative to project root if available, or absolute file URI).
  final String? filePath;

  /// The line number in source code (1-indexed).
  final int? line;

  /// The column number in source code (1-indexed).
  final int? column;

  /// Whether this widget was instantiated by the user's project code
  /// (as opposed to Flutter framework internals like Padding/Semantics).
  final bool isLocalProject;

  /// Hierarchical ancestry path from root down to this widget.
  final List<String> ancestry;

  /// Global screen bounding box of the widget.
  final Rect? bounds;

  /// Extra diagnostic or parameter properties if available.
  final Map<String, dynamic> extraProperties;

  /// Raw PNG bytes of the captured widget screenshot (if available).
  final Uint8List? screenshotBytes;

  /// Base64 data URI of the captured widget screenshot (e.g. "data:image/png;base64,...").
  final String? screenshotBase64;

  /// Local filesystem path to the saved screenshot PNG file (if saved to disk).
  final String? screenshotPath;

  /// Whether a visual screenshot has been captured for this widget.
  bool get hasScreenshot =>
      screenshotBytes != null || screenshotBase64 != null || screenshotPath != null;

  /// Formatted location string, e.g., "lib/home.dart:42:10"
  String get locationString {
    if (filePath == null) return 'unknown location';
    final lineStr = line != null ? ':$line' : '';
    final colStr = (line != null && column != null) ? ':$column' : '';
    return '$filePath$lineStr$colStr';
  }

  /// Compact ancestry string, e.g. "App > Home > Card > ProfileAvatar"
  String get ancestryString => ancestry.isEmpty ? widgetName : ancestry.join(' > ');

  /// Dimensions string, e.g. "320.0 x 48.0"
  String get dimensionsString {
    if (bounds == null) return 'unknown';
    return '${bounds!.width.toStringAsFixed(1)} x ${bounds!.height.toStringAsFixed(1)}';
  }

  /// Returns a copy of this result with the given fields replaced.
  GrabResult copyWith({
    String? widgetName,
    String? filePath,
    int? line,
    int? column,
    bool? isLocalProject,
    List<String>? ancestry,
    Rect? bounds,
    Map<String, dynamic>? extraProperties,
    Uint8List? screenshotBytes,
    String? screenshotBase64,
    String? screenshotPath,
  }) {
    return GrabResult(
      widgetName: widgetName ?? this.widgetName,
      filePath: filePath ?? this.filePath,
      line: line ?? this.line,
      column: column ?? this.column,
      isLocalProject: isLocalProject ?? this.isLocalProject,
      ancestry: ancestry ?? this.ancestry,
      bounds: bounds ?? this.bounds,
      extraProperties: extraProperties ?? this.extraProperties,
      screenshotBytes: screenshotBytes ?? this.screenshotBytes,
      screenshotBase64: screenshotBase64 ?? this.screenshotBase64,
      screenshotPath: screenshotPath ?? this.screenshotPath,
    );
  }
}
