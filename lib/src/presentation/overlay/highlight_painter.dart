import 'package:flutter/material.dart';

/// CustomPainter that renders visual inspection highlights around selected widgets.
class HighlightPainter extends CustomPainter {
  const HighlightPainter({
    required this.bounds,
    this.primaryColor = const Color(0xFF6366F1), // Indigo accent
    this.fillColor = const Color(0x1F6366F1),
    this.label,
  });

  final Rect? bounds;
  final Color primaryColor;
  final Color fillColor;
  final String? label;

  @override
  void paint(Canvas canvas, Size size) {
    if (bounds == null) return;

    final rect = bounds!;

    // 1. Fill highlight
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 2. Stroke outline
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, strokePaint);

    // 3. Draw corner brackets/handles
    final cornerLength = 8.0;
    final cornerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top-Left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLength), cornerPaint);

    // Top-Right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, cornerLength), cornerPaint);

    // Bottom-Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -cornerLength), cornerPaint);

    // Bottom-Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -cornerLength), cornerPaint);

    // 4. Render dimensions badge
    final sizeText = label ?? '${rect.width.toStringAsFixed(0)} × ${rect.height.toStringAsFixed(0)}';
    final textSpan = TextSpan(
      text: sizeText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgePadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    final badgeWidth = textPainter.width + badgePadding.horizontal;
    final badgeHeight = textPainter.height + badgePadding.vertical;

    // Position badge just below bottom-right or above top-right if near bottom edge
    var badgeX = rect.right - badgeWidth;
    var badgeY = rect.bottom + 4;
    if (badgeY + badgeHeight > size.height) {
      badgeY = rect.top - badgeHeight - 4;
    }
    if (badgeX < 0) badgeX = 0;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight),
      const Radius.circular(4),
    );

    final badgeBgPaint = Paint()..color = const Color(0xE61E1E2E);
    canvas.drawRRect(badgeRect, badgeBgPaint);
    textPainter.paint(canvas, Offset(badgeX + badgePadding.left, badgeY + badgePadding.top));
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return oldDelegate.bounds != bounds ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.label != label;
  }
}
