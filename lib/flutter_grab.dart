import 'package:flutter/material.dart';

import 'src/core/grab_controller.dart';
import 'src/presentation/flutter_grab_wrapper.dart';

export 'src/core/grab_controller.dart';
export 'src/core/grab_result.dart';
export 'src/core/widget_candidate.dart';
export 'src/formatters/ai_prompt_formatter.dart';
export 'src/inspector/hit_tester.dart';
export 'src/inspector/widget_inspector_bridge.dart';
export 'src/presentation/flutter_grab_wrapper.dart';

/// The primary widget entry point for Flutter Grab.
///
/// You can wrap your app root widget:
/// ```dart
/// FlutterGrab(
///   child: MyApp(),
/// )
/// ```
///
/// Or integrate via [MaterialApp.builder]:
/// ```dart
/// MaterialApp(
///   builder: FlutterGrab.builder,
///   home: const HomeScreen(),
/// )
/// ```
class FlutterGrab extends StatelessWidget {
  const FlutterGrab({
    super.key,
    required this.child,
    this.controller,
    this.showFloatingTrigger = true,
    this.enableKeyboardShortcut = true,
  });

  final Widget child;
  final GrabController? controller;
  final bool showFloatingTrigger;
  final bool enableKeyboardShortcut;

  /// Helper builder for [MaterialApp.builder] or [WidgetsApp.builder].
  static Widget builder(BuildContext context, Widget? child) {
    return FlutterGrab(
      child: child ?? const SizedBox.shrink(),
    );
  }

  /// Chains FlutterGrab with an existing [TransitionBuilder].
  ///
  /// Useful if your MaterialApp already uses a custom builder:
  /// ```dart
  /// MaterialApp(
  ///   builder: FlutterGrab.chain(myExistingBuilder),
  ///   home: const HomeScreen(),
  /// )
  /// ```
  static TransitionBuilder chain([TransitionBuilder? existingBuilder]) {
    return (BuildContext context, Widget? child) {
      final builtChild = existingBuilder != null ? existingBuilder(context, child) : child;
      return FlutterGrab(child: builtChild ?? const SizedBox.shrink());
    };
  }

  @override
  Widget build(BuildContext context) {
    return FlutterGrabWrapper(
      controller: controller,
      showFloatingTrigger: showFloatingTrigger,
      enableKeyboardShortcut: enableKeyboardShortcut,
      child: child,
    );
  }
}
