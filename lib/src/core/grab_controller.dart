import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pasteboard/pasteboard.dart';

import '../formatters/ai_prompt_formatter.dart';
import '../inspector/hit_tester.dart';
import '../inspector/widget_inspector_bridge.dart';
import '../inspector/widget_screenshotter.dart';
import '../utils/file_saver.dart';
import 'grab_result.dart';
import 'widget_candidate.dart';

/// Callback signature for capturing widget screenshots.
typedef ScreenshotCaptureCallback = Future<WidgetScreenshot?> Function(Rect? bounds);

/// State controller that orchestrates widget hit-testing, metadata resolution, and clipboard export.
///
/// Follows the architecture:
/// 1. [HitTester] resolves: Pointer ➔ RenderView / RenderObject ➔ Element
/// 2. [WidgetInspectorBridge] resolves: Element ➔ WidgetInspectorService ➔ CreationLocation
class GrabController extends ChangeNotifier {
  GrabController({
    this.hitTester = const HitTester(),
    this.bridge = const WidgetInspectorBridge(),
    this.formatter = const AiPromptFormatter(),
  });

  final HitTester hitTester;
  final WidgetInspectorBridge bridge;
  final AiPromptFormatter formatter;

  ScreenshotCaptureCallback? _screenshotCaptureCallback;

  bool _isActive = false;
  bool _isInspecting = false;
  bool _hasCopied = false;
  bool _hasCopiedScreenshot = false;
  bool _isCapturingScreenshot = false;

  WidgetCandidate? _hoveredCandidate;
  WidgetCandidate? _selectedCandidate;
  List<WidgetCandidate> _candidateTree = const [];
  final List<WidgetCandidate> _batchCandidates = [];
  bool _isMultiSelectMode = false;

  Timer? _copiedFeedbackTimer;

  /// Whether Grab mode is currently toggled on.
  bool get isActive => _isActive;

  /// Whether the user is actively hovering or touching to inspect widgets.
  bool get isInspecting => _isInspecting;

  /// Whether context was recently copied to clipboard (used for feedback UI).
  bool get hasCopied => _hasCopied;

  /// Whether context including a visual screenshot was recently copied.
  bool get hasCopiedScreenshot => _hasCopiedScreenshot;

  /// Whether a screenshot is currently being captured.
  bool get isCapturingScreenshot => _isCapturingScreenshot;

  /// Sets the callback to capture screenshots from the app root RepaintBoundary.
  void setScreenshotCaptureCallback(ScreenshotCaptureCallback? callback) {
    _screenshotCaptureCallback = callback;
  }

  /// Whether multi-widget selection mode is enabled.
  bool get isMultiSelectMode => _isMultiSelectMode;

  /// List of queued widgets in the multi-select batch.
  List<WidgetCandidate> get batchCandidates => List.unmodifiable(_batchCandidates);

  /// Whether there are multiple widgets currently batched.
  bool get hasBatch => _batchCandidates.isNotEmpty;

  /// The widget currently under the cursor/pointer.
  WidgetCandidate? get hoveredCandidate => _hoveredCandidate;

  /// The widget currently locked/selected.
  WidgetCandidate? get selectedCandidate => _selectedCandidate;

  /// The candidate currently in focus (selected takes precedence over hovered).
  WidgetCandidate? get activeCandidate => _selectedCandidate ?? _hoveredCandidate;

  /// The active GrabResult (if any).
  GrabResult? get activeResult => activeCandidate?.result;

  /// Ancestor candidate chain for the active selection.
  List<WidgetCandidate> get candidateTree => _candidateTree;

  /// Toggles Grab mode on or off.
  void toggleActive() {
    _isActive = !_isActive;
    if (!_isActive) {
      _clear();
    }
    notifyListeners();
  }

  /// Activates Grab mode.
  void activate() {
    if (!_isActive) {
      _isActive = true;
      notifyListeners();
    }
  }

  /// Deactivates Grab mode and clears all selections.
  void deactivate() {
    if (_isActive) {
      _isActive = false;
      _clear();
      notifyListeners();
    }
  }

  /// Updates inspection coordinates during mouse hover or finger drag.
  ///
  /// Uses [HitTester] to find hit RenderObjects and Elements, then lazily
  /// resolves source metadata via [WidgetInspectorBridge] for the focused candidate.
  void inspectAt(Offset position, {int? viewId, RenderBox? rootRenderBox}) {
    if (!_isActive) return;

    final candidates = hitTester.hitTest(
      position,
      viewId: viewId,
      rootRenderBox: rootRenderBox,
    );
    if (candidates.isEmpty) return;

    _candidateTree = candidates;
    final best = HitTester.findBestCandidate(candidates);

    if (best != null && best.result == null) {
      best.attachResult(bridge.resolveElement(best.element));
    }

    _hoveredCandidate = best;
    _isInspecting = true;
    notifyListeners();
  }

  /// Selects and locks a widget upon click or tap.
  ///
  /// If [isMultiSelectMode] is active, also appends it to [batchCandidates].
  void selectCandidate(WidgetCandidate candidate) {
    if (candidate.result == null) {
      candidate.attachResult(bridge.resolveElement(candidate.element));
    }
    _selectedCandidate = candidate;
    _isInspecting = false;

    if (_isMultiSelectMode) {
      _addToBatchInternal(candidate);
    }

    notifyListeners();
  }

  /// Toggles multi-select mode. If turning on and there is an active candidate,
  /// it is automatically added to the batch.
  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (_isMultiSelectMode && _selectedCandidate != null) {
      _addToBatchInternal(_selectedCandidate!);
    }
    notifyListeners();
  }

  /// Adds a candidate to the multi-widget batch queue.
  void addToBatch(WidgetCandidate candidate) {
    _isMultiSelectMode = true;
    _addToBatchInternal(candidate);
    notifyListeners();
  }

  void _addToBatchInternal(WidgetCandidate candidate) {
    if (candidate.result == null) {
      candidate.attachResult(bridge.resolveElement(candidate.element));
    }
    final alreadyExists = _batchCandidates.any((c) => c.element == candidate.element);
    if (!alreadyExists) {
      _batchCandidates.add(candidate);
    }
  }

  /// Removes a candidate from the batch queue by index.
  void removeFromBatch(int index) {
    if (index >= 0 && index < _batchCandidates.length) {
      _batchCandidates.removeAt(index);
      if (_batchCandidates.isEmpty) {
        _isMultiSelectMode = false;
      }
      notifyListeners();
    }
  }

  /// Clears the multi-select batch queue.
  void clearBatch() {
    _batchCandidates.clear();
    _isMultiSelectMode = false;
    notifyListeners();
  }

  /// Switches selection to a specific ancestor candidate from [candidateTree].
  void selectCandidateByIndex(int index) {
    if (index >= 0 && index < _candidateTree.length) {
      final candidate = _candidateTree[index];
      if (candidate.result == null) {
        candidate.attachResult(bridge.resolveElement(candidate.element));
      }
      _selectedCandidate = candidate;
      notifyListeners();
    }
  }

  /// Copies the currently active candidate (or entire multi-widget batch) to the system clipboard.
  Future<bool> copyActiveContext() async {
    final String formattedText;

    if (_batchCandidates.length > 1) {
      // Ensure all batch candidates have resolved metadata
      for (final c in _batchCandidates) {
        if (c.result == null) {
          c.attachResult(bridge.resolveElement(c.element));
        }
      }
      final results = _batchCandidates.map((c) => c.result!).toList();
      formattedText = formatter.formatMultiple(results);
    } else {
      var result = activeResult;
      // Ensure metadata is resolved before copying
      if (result == null && activeCandidate != null) {
        result = bridge.resolveElement(activeCandidate!.element);
        activeCandidate!.attachResult(result);
      }

      if (result == null) return false;
      formattedText = formatter.format(result);
    }

    await Clipboard.setData(ClipboardData(text: formattedText));

    // Print to console so developers running on wireless/remote devices see it in their terminal
    debugPrint('\n════════════════════ [🎯 Flutter Grab AI Context] ════════════════════\n'
        '$formattedText\n'
        '═══════════════════════════════════════════════════════════════════════\n');

    // Optional haptic feedback
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    _hasCopied = true;
    notifyListeners();

    _copiedFeedbackTimer?.cancel();
    _copiedFeedbackTimer = Timer(const Duration(milliseconds: 2000), () {
      _hasCopied = false;
      notifyListeners();
    });

    return true;
  }

  /// Captures a visual screenshot for the given [candidate] if not already captured.
  Future<WidgetScreenshot?> captureScreenshotForCandidate(WidgetCandidate candidate) async {
    if (_screenshotCaptureCallback == null) return null;
    final shot = await _screenshotCaptureCallback!(candidate.bounds);
    if (shot != null) {
      final baseResult = candidate.result ?? bridge.resolveElement(candidate.element);
      candidate.attachResult(baseResult.copyWith(
        screenshotBytes: shot.bytes,
        screenshotBase64: shot.base64DataUri,
      ));
      notifyListeners();
    }
    return shot;
  }

  /// Captures visual screenshot, saves PNG to disk, and writes context and image to the clipboard.
  Future<bool> copyActiveContextWithScreenshot() async {
    final candidate = activeCandidate;
    if (candidate == null) return false;

    _isCapturingScreenshot = true;
    notifyListeners();

    try {
      if (candidate.result?.screenshotBytes == null) {
        await captureScreenshotForCandidate(candidate);
      }

      final bytes = candidate.result?.screenshotBytes;
      if (bytes != null) {
        // 1. Save screenshot PNG directly to disk
        final savedPath = saveScreenshotFile(candidate.widgetName, bytes);
        if (savedPath != null) {
          final base = candidate.result ?? bridge.resolveElement(candidate.element);
          candidate.attachResult(base.copyWith(screenshotPath: savedPath));
        }

        // 2. Format AI prompt with code context AND the screenshot file link
        final currentResult = candidate.result ?? bridge.resolveElement(candidate.element);
        final formattedText = formatter.format(currentResult);

        // 3. Set text clipboard so prompt can be pasted into any AI chat / editor
        await Clipboard.setData(ClipboardData(text: formattedText));

        // 4. Also write binary PNG image to the system clipboard (Pasteboard)
        // so image-receiving apps (Preview, Slack, Figma, image chat) receive the image directly
        try {
          await Pasteboard.writeImage(bytes);
          if (savedPath != null) {
            await Pasteboard.writeFiles([savedPath]);
          }
        } catch (e) {
          debugPrint(
            '[Flutter Grab] Note: Pasteboard native image copy unavailable ($e). '
            'Restart "flutter run" to link native plugins. Screenshot saved to file://$savedPath',
          );
        }

        debugPrint('\n════════════════════ [🎯 Flutter Grab Screenshot Copied] ════════════════════\n'
            'Target Widget: ${candidate.widgetName} (${candidate.result?.locationString})\n'
            'Render Size: ${candidate.result?.dimensionsString}\n'
            '${savedPath != null ? "📸 Screenshot File: file://$savedPath\n" : ""}'
            '📸 Visual context copied to clipboard!\n'
            '══════════════════════════════════════════════════════════════════════════════\n');

        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}

        _hasCopiedScreenshot = true;
        notifyListeners();
        _copiedFeedbackTimer?.cancel();
        _copiedFeedbackTimer = Timer(const Duration(milliseconds: 2000), () {
          _hasCopiedScreenshot = false;
          notifyListeners();
        });

        return true;
      }

      return false;
    } catch (e, st) {
      debugPrint('[Flutter Grab] Error capturing screenshot: $e\n$st');
      return false;
    } finally {
      _isCapturingScreenshot = false;
      notifyListeners();
    }
  }

  /// Clears current selection while keeping Grab mode active.
  void clearSelection() {
    _selectedCandidate = null;
    _hoveredCandidate = null;
    _candidateTree = const [];
    notifyListeners();
  }

  void _clear() {
    _isInspecting = false;
    _selectedCandidate = null;
    _hoveredCandidate = null;
    _candidateTree = const [];
    _batchCandidates.clear();
    _isMultiSelectMode = false;
    _hasCopied = false;
    _hasCopiedScreenshot = false;
    _isCapturingScreenshot = false;
    _copiedFeedbackTimer?.cancel();
  }

  @override
  void dispose() {
    _copiedFeedbackTimer?.cancel();
    super.dispose();
  }
}
