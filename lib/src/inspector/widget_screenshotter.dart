import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Data class representing a captured widget screenshot.
class WidgetScreenshot {
  const WidgetScreenshot({
    required this.bytes,
    required this.base64DataUri,
    required this.width,
    required this.height,
  });

  /// Raw PNG bytes.
  final Uint8List bytes;

  /// Base64 data URI formatted as `data:image/png;base64,...`
  final String base64DataUri;

  /// Logical width of the cropped snapshot.
  final double width;

  /// Logical height of the cropped snapshot.
  final double height;
}

/// Utility for capturing and cropping widget screenshots from a [RenderRepaintBoundary].
class WidgetScreenshotter {
  const WidgetScreenshotter({
    this.defaultPixelRatio = 2.0,
    this.padding = 2.0,
  });

  /// Default pixel ratio used for retina/crisp snapshot capture (default 2.0).
  final double defaultPixelRatio;

  /// Extra padding (in logical pixels) around the widget bounds to avoid clipping shadows/borders.
  final double padding;

  /// Captures a screenshot of the widget bounded by [bounds] from the given [boundary].
  ///
  /// If [bounds] is null, captures the full boundary.
  /// Returns a [WidgetScreenshot] containing raw PNG bytes and a Base64 data URI.
  Future<WidgetScreenshot?> capture({
    required RenderRepaintBoundary boundary,
    Rect? bounds,
    double? pixelRatio,
  }) async {
    if (!boundary.attached || !boundary.hasSize || boundary.size.isEmpty) {
      return null;
    }

    final effectivePixelRatio = pixelRatio ?? defaultPixelRatio;

    try {
      final fullImage = await boundary.toImage(pixelRatio: effectivePixelRatio);

      // If no bounds provided, return the full boundary image
      if (bounds == null || bounds.isEmpty) {
        final byteData = await fullImage.toByteData(format: ui.ImageByteFormat.png);
        fullImage.dispose();
        if (byteData == null) return null;

        final bytes = byteData.buffer.asUint8List();
        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
        return WidgetScreenshot(
          bytes: bytes,
          base64DataUri: base64String,
          width: boundary.size.width,
          height: boundary.size.height,
        );
      }

      // Calculate crop coordinates scaled by pixelRatio
      final double fullWidth = fullImage.width.toDouble();
      final double fullHeight = fullImage.height.toDouble();

      final double rawLeft = (bounds.left - padding) * effectivePixelRatio;
      final double rawTop = (bounds.top - padding) * effectivePixelRatio;
      final double rawRight = (bounds.right + padding) * effectivePixelRatio;
      final double rawBottom = (bounds.bottom + padding) * effectivePixelRatio;

      // Clamp coordinates to full image dimensions
      final double cropLeft = rawLeft.clamp(0.0, fullWidth);
      final double cropTop = rawTop.clamp(0.0, fullHeight);
      final double cropRight = rawRight.clamp(0.0, fullWidth);
      final double cropBottom = rawBottom.clamp(0.0, fullHeight);

      final double cropWidth = cropRight - cropLeft;
      final double cropHeight = cropBottom - cropTop;

      if (cropWidth <= 1 || cropHeight <= 1) {
        fullImage.dispose();
        return null;
      }

      // Crop the image using Canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final srcRect = Rect.fromLTWH(cropLeft, cropTop, cropWidth, cropHeight);
      final dstRect = Rect.fromLTWH(0, 0, cropWidth, cropHeight);

      canvas.drawImageRect(fullImage, srcRect, dstRect, Paint());
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropWidth.round(), cropHeight.round());
      fullImage.dispose();

      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      croppedImage.dispose();

      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final base64String = 'data:image/png;base64,${base64Encode(bytes)}';

      return WidgetScreenshot(
        bytes: bytes,
        base64DataUri: base64String,
        width: cropWidth / effectivePixelRatio,
        height: cropHeight / effectivePixelRatio,
      );
    } catch (_) {
      return null;
    }
  }
}
