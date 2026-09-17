import 'package:flutter/material.dart';
import '../../core/grab_controller.dart';
import '../../core/widget_candidate.dart';

/// Floating HUD banner that displays selected widget context, breadcrumbs, and copy button.
///
/// Features smart adaptive positioning: automatically docks at the top when inspecting
/// widgets in the lower half of the screen (e.g. BottomNavigationBar), and provides
/// manual flip controls (button & swipe gestures) so developers can reposition anytime.
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final candidate = widget.controller.activeCandidate;
        if (candidate == null) {
          _lastCandidate = null;
          _manualPositionOverride = null;
          return const SizedBox.shrink();
        }

        // Reset manual position override when selecting a different widget
        if (candidate.element != _lastCandidate?.element) {
          _lastCandidate = candidate;
          _manualPositionOverride = null;
        }

        final result = candidate.result;
        final hasCopied = widget.controller.hasCopied;

        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final safeTop = mediaQuery.padding.top;
        final safeBottom = mediaQuery.padding.bottom;

        // Smart adaptive positioning:
        // If the inspected widget is in the lower 45% of the screen (e.g. bottom nav, fab),
        // dock HUD at the top so it never covers the target widget.
        final bounds = candidate.bounds;
        final isTargetInLowerHalf =
            bounds != null ? (bounds.center.dy > screenHeight * 0.45) : false;

        final showAtTop = _manualPositionOverride ?? isTargetInLowerHalf;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: 16,
          right: 16,
          top: showAtTop ? safeTop + 12 : null,
          bottom: !showAtTop ? safeBottom + 16 : null,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              final vy = details.primaryVelocity ?? 0;
              if (vy > 250 && showAtTop) {
                // Swiped down while at top -> move to bottom
                setState(() => _manualPositionOverride = false);
              } else if (vy < -250 && !showAtTop) {
                // Swiped up while at bottom -> move to top
                setState(() => _manualPositionOverride = true);
              }
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xF0181825), // Sleek deep slate
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0x336366F1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Widget name + File Location + Action Buttons
                    Row(
                      children: [
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

                        // Widget Name
                        Expanded(
                          child: Text(
                            candidate.widgetName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Copy Button
                        ElevatedButton.icon(
                          onPressed: () => widget.controller.copyActiveContext(),
                          icon: Icon(
                            hasCopied ? Icons.check_circle : Icons.copy_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          label: Text(
                            hasCopied ? 'Copied!' : 'Grab Context',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                hasCopied ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Flip Position Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _manualPositionOverride = !showAtTop;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Tooltip(
                            message: showAtTop ? 'Move to bottom' : 'Move to top',
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                showAtTop
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 18,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 2),

                        // Close button
                        InkWell(
                          onTap: () {
                            widget.controller.clearSelection();
                            widget.onClose?.call();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded, size: 18, color: Colors.white60),
                          ),
                        ),
                      ],
                    ),

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
                          if (candidate.bounds != null)
                            Text(
                              '${candidate.bounds!.width.toStringAsFixed(1)} x ${candidate.bounds!.height.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
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
