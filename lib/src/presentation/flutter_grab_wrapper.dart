import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/grab_controller.dart';
import 'overlay/floating_trigger.dart';
import 'overlay/grab_hud.dart';
import 'overlay/highlight_painter.dart';

/// Intent for toggling Grab mode via keyboard shortcut.
class ToggleGrabIntent extends Intent {
  const ToggleGrabIntent();
}

/// The root container and overlay manager for Flutter Grab.
class FlutterGrabWrapper extends StatefulWidget {
  const FlutterGrabWrapper({
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

  @override
  State<FlutterGrabWrapper> createState() => _FlutterGrabWrapperState();
}

class _FlutterGrabWrapperState extends State<FlutterGrabWrapper> {
  late final GrabController _controller;
  bool _createdController = false;

  final GlobalKey _appContentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = GrabController();
      _createdController = true;
    }
  }

  @override
  void dispose() {
    if (_createdController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 0% overhead in release/profile builds
    if (!kDebugMode) {
      return widget.child;
    }

    Widget content = ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isActive = _controller.isActive;
        final candidate = _controller.activeCandidate;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base App Content (Scoped for Hit Testing)
            KeyedSubtree(
              key: _appContentKey,
              child: widget.child,
            ),

            // Active Inspection Layer
            if (isActive) ...[
              // Hit detection and pointer listener
              Positioned.fill(
                child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  onHover: (event) {
                    final viewId = View.maybeOf(context)?.viewId;
                    final rootBox = _appContentKey.currentContext?.findRenderObject() as RenderBox?;
                    _controller.inspectAt(event.position, viewId: viewId, rootRenderBox: rootBox);
                  },
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerMove: (event) {
                      final viewId = View.maybeOf(context)?.viewId;
                      final rootBox = _appContentKey.currentContext?.findRenderObject() as RenderBox?;
                      _controller.inspectAt(event.position, viewId: viewId, rootRenderBox: rootBox);
                    },
                    onPointerDown: (event) {
                      final viewId = View.maybeOf(context)?.viewId;
                      final rootBox = _appContentKey.currentContext?.findRenderObject() as RenderBox?;
                      _controller.inspectAt(event.position, viewId: viewId, rootRenderBox: rootBox);
                    },
                    onPointerUp: (event) {
                      final hovered = _controller.hoveredCandidate;
                      if (hovered != null) {
                        _controller.selectCandidate(hovered);
                      }
                    },
                  ),
                ),
              ),

              // Highlight outline painter
              if (candidate?.bounds != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HighlightPainter(
                        bounds: candidate!.bounds,
                        label: '${candidate.widgetName} (${candidate.bounds!.width.toStringAsFixed(0)} × ${candidate.bounds!.height.toStringAsFixed(0)})',
                      ),
                    ),
                  ),
                ),

              // Floating Context HUD
              GrabHud(controller: _controller),
            ],

            // Floating Draggable Trigger Button
            if (widget.showFloatingTrigger)
              FloatingTrigger(controller: _controller),
          ],
        );
      },
    );

    // Add keyboard shortcuts (Cmd+Shift+C or Ctrl+Shift+C)
    if (widget.enableKeyboardShortcut) {
      content = Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          // Mac: Cmd+Shift+C
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true):
              const ToggleGrabIntent(),
          // Windows / Linux: Ctrl+Shift+C
          const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
              const ToggleGrabIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ToggleGrabIntent: CallbackAction<ToggleGrabIntent>(
              onInvoke: (_) {
                _controller.toggleActive();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: false,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
