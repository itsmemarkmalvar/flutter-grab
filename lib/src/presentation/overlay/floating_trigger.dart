import 'package:flutter/material.dart';
import '../../core/grab_controller.dart';

/// Draggable floating button that toggles Grab mode.
class FloatingTrigger extends StatefulWidget {
  const FloatingTrigger({
    super.key,
    required this.controller,
    this.initialOffset = const Offset(20, 100),
  });

  final GrabController controller;
  final Offset initialOffset;

  @override
  State<FloatingTrigger> createState() => _FloatingTriggerState();
}

class _FloatingTriggerState extends State<FloatingTrigger> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialOffset;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isActive = widget.controller.isActive;

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            child: Material(
              elevation: isActive ? 12 : 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isActive ? const Color(0xFF818CF8) : const Color(0x33FFFFFF),
                  width: isActive ? 2 : 1,
                ),
              ),
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xEE1E1E2E),
              child: InkWell(
                onTap: () => widget.controller.toggleActive(),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.crop_free_rounded : Icons.search_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Grabbing' : 'Grab',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981), // Pulsing green dot
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
