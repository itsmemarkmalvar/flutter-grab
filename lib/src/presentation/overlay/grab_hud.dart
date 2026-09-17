import 'package:flutter/material.dart';
import '../../core/grab_controller.dart';
import '../../core/widget_candidate.dart';

/// Floating HUD banner that displays selected widget context, breadcrumbs, and copy button.
///
/// Features:
/// 1. Freeform 2D Dragging across the screen.
/// 2. Video-call / PiP style tucking: minimizes to a side bezel tab so 100% of app UI is unobstructed.
/// 3. Smart adaptive positioning: auto-positions away from target element.
/// 4. Multi-Grab batch tray: collect and copy multiple widgets at once for AI prompts.
class GrabHud extends StatefulWidget {
  const GrabHud({
    super.key,
    required this.controller,
    this.onClose,
  });

  final GrabController controller;
  final VoidCallback? onClose;

  @override
  State<GrabHud> createState() => _GrabHudState();
}

class _GrabHudState extends State<GrabHud> {
  bool? _manualPositionOverride;
  WidgetCandidate? _lastCandidate;

  // Freeform dragging & PiP edge-tuck state
  double? _customTop;
  bool _isTucked = false;
  bool _tuckedToLeft = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final candidate = widget.controller.activeCandidate;
        if (candidate == null) {
          _lastCandidate = null;
          _manualPositionOverride = null;
          _customTop = null;
          _isTucked = false;
          return const SizedBox.shrink();
        }

        // Reset manual position override when selecting a different widget
        if (candidate.element != _lastCandidate?.element) {
          _lastCandidate = candidate;
          _manualPositionOverride = null;
          _customTop = null;
          _isTucked = false;
        }

        final result = candidate.result;
        final hasCopied = widget.controller.hasCopied;
        final isMulti = widget.controller.isMultiSelectMode;
        final batch = widget.controller.batchCandidates;

        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final safeTop = mediaQuery.padding.top;
        final safeBottom = mediaQuery.padding.bottom;

        final defaultTop = safeTop + 14;
        final defaultBottom = screenHeight - safeBottom - 180;

        // Smart adaptive positioning (if not manually dragged)
        final bounds = candidate.bounds;
        final isTargetInLowerHalf =
            bounds != null ? (bounds.center.dy > screenHeight * 0.45) : false;

        final showAtTop = _manualPositionOverride ?? isTargetInLowerHalf;
        final currentTop = _customTop ?? (showAtTop ? defaultTop : defaultBottom);

        // ─────────────────────────────────────────────────────────────
        // 1. Tucked State (Video-call / PiP edge tab)
        // ─────────────────────────────────────────────────────────────
        if (_isTucked) {
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            top: currentTop.clamp(safeTop + 10, screenHeight - safeBottom - 50),
            left: _tuckedToLeft ? 0 : null,
            right: !_tuckedToLeft ? 0 : null,
            child: GestureDetector(
              onTap: () => setState(() => _isTucked = false),
              onPanUpdate: (details) {
                setState(() {
                  _customTop = (currentTop + details.delta.dy)
                      .clamp(safeTop + 10, screenHeight - safeBottom - 50);
                });
              },
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.horizontal(
                  left: _tuckedToLeft ? Radius.zero : const Radius.circular(20),
                  right: _tuckedToLeft ? const Radius.circular(20) : Radius.zero,
                ),
                color: const Color(0xF0181825),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                      left: _tuckedToLeft ? Radius.zero : const Radius.circular(20),
                      right: _tuckedToLeft ? const Radius.circular(20) : Radius.zero,
                    ),
                    border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _tuckedToLeft
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text('🎯', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      if (batch.length > 1) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${batch.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          candidate.widgetName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // ─────────────────────────────────────────────────────────────
        // 2. Full HUD Card (Draggable & Tuckable)
        // ─────────────────────────────────────────────────────────────
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          left: 16,
          right: 16,
          top: currentTop.clamp(safeTop + 10, screenHeight - safeBottom - 190),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _customTop = (currentTop + details.delta.dy)
                    .clamp(safeTop + 10, screenHeight - safeBottom - 190);
              });
            },
            onPanEnd: (details) {
              final vx = details.velocity.pixelsPerSecond.dx;
              // Flick right or left to tuck
              if (vx > 600) {
                setState(() {
                  _isTucked = true;
                  _tuckedToLeft = false;
                });
              } else if (vx < -600) {
                setState(() {
                  _isTucked = true;
                  _tuckedToLeft = true;
                });
              }
            },
            child: Material(
              elevation: 10,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF181825), // 100% solid opaque to prevent underlying UI bleed-through
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181825),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0x336366F1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title Bar (Drag Handle + Badge + Widget Name + Utility Icons)
                    Row(
                      children: [
                        // Drag Indicator
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.drag_indicator_rounded,
                              size: 16, color: Colors.white38),
                        ),

                        // Accent badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: candidate.isLocalProject
                                ? const Color(0xFF10B981) // Green for user code
                                : const Color(0xFF6366F1), // Indigo for framework/deps
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            candidate.isLocalProject ? 'LOCAL' : 'WIDGET',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Widget Name (Takes remaining space without crowding)
                        Expanded(
                          child: Text(
                            candidate.widgetName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Flip Position Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _manualPositionOverride = !showAtTop;
                              _customTop = !showAtTop ? defaultTop : defaultBottom;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              showAtTop
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 16,
                              color: Colors.white60,
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // PiP Tuck to Side Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isTucked = true;
                              _tuckedToLeft = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.white60),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // Close button
                        InkWell(
                          onTap: () {
                            widget.controller.clearSelection();
                            widget.onClose?.call();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded, size: 17, color: Colors.white60),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Row 2: Action Bar (Multi-Grab Toggle + Primary Copy Button)
                    Row(
                      children: [
                        // Multi-Grab Toggle Button
                        InkWell(
                          onTap: () => widget.controller.toggleMultiSelectMode(),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMulti
                                  ? const Color(0xFF10B981)
                                  : const Color(0x226366F1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isMulti
                                    ? const Color(0xFF34D399)
                                    : const Color(0x446366F1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMulti ? Icons.check_box_rounded : Icons.add_box_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isMulti ? 'Multi (${batch.length})' : '+ Multi',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Copy Button (Expanded with ample touch target)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.controller.copyActiveContext(),
                            icon: Icon(
                              hasCopied ? Icons.check_circle : Icons.copy_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            label: Text(
                              hasCopied
                                  ? (batch.length > 1 ? 'Copied All (${batch.length})!' : 'Copied!')
                                  : (batch.length > 1
                                      ? 'Grab All (${batch.length})'
                                      : 'Grab Context'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasCopied
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Multi-Grab Batch Queue Chips
                    if (batch.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0x15FFFFFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Queued for AI:',
                              style: TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 22,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: batch.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                                  itemBuilder: (context, i) {
                                    final b = batch[i];
                                    final isFocused = b.element == candidate.element;
                                    return GestureDetector(
                                      onTap: () => widget.controller.selectCandidate(b),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isFocused
                                              ? const Color(0xFF6366F1)
                                              : const Color(0x336366F1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isFocused
                                                ? const Color(0xFF818CF8)
                                                : Colors.transparent,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              b.widgetName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => widget.controller.removeFromBatch(i),
                                              child: const Icon(Icons.close, size: 10, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => widget.controller.clearBatch(),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // File Path & Line Info
                    if (candidate.filePath != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.code_rounded, size: 13, color: Colors.white54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              result?.locationString ?? candidate.filePath!,
                              style: const TextStyle(
                                color: Color(0xFF93C5FD), // Soft light blue
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (candidate.bounds != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${candidate.bounds!.width.toStringAsFixed(1)} x ${candidate.bounds!.height.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Ancestry Breadcrumbs
                    if (widget.controller.candidateTree.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 8),
                      _buildBreadcrumbs(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final candidates = widget.controller.candidateTree;
    final selected = widget.controller.selectedCandidate;

    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: candidates.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 14, color: Colors.white24),
        ),
        itemBuilder: (context, index) {
          final c = candidates[index];
          final isSelected = c.element == selected?.element;

          return InkWell(
            onTap: () => widget.controller.selectCandidateByIndex(index),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF818CF8) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.isLocalProject)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    c.widgetName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
