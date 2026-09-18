import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_grab/flutter_grab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetScreenshotter', () {
    testWidgets('captures full boundary and cropped bounds', (tester) async {
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.blue,
                alignment: Alignment.topLeft,
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      const screenshotter = WidgetScreenshotter(defaultPixelRatio: 1.0, padding: 0.0);

      // 1. Capture full boundary
      final fullShot = await tester.runAsync(() => screenshotter.capture(
        boundary: boundary,
        pixelRatio: 1.0,
      ));

      expect(fullShot, isNotNull);
      expect(fullShot!.bytes, isNotEmpty);
      expect(fullShot.base64DataUri, startsWith('data:image/png;base64,'));
      expect(fullShot.width, equals(200));
      expect(fullShot.height, equals(200));

      // 2. Capture cropped bounds (the red box 50x50 at top-left)
      final croppedShot = await tester.runAsync(() => screenshotter.capture(
        boundary: boundary,
        bounds: const Rect.fromLTWH(0, 0, 50, 50),
        pixelRatio: 1.0,
      ));

      expect(croppedShot, isNotNull);
      expect(croppedShot!.bytes, isNotEmpty);
      expect(croppedShot.base64DataUri, startsWith('data:image/png;base64,'));
      expect(croppedShot.width, closeTo(50, 1.0));
      expect(croppedShot.height, closeTo(50, 1.0));
    });

    testWidgets('handles boundary clamping for overflowing bounds gracefully', (tester) async {
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: const SizedBox(
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      const screenshotter = WidgetScreenshotter(defaultPixelRatio: 1.0);

      // Bounds that partially overflow beyond the 100x100 boundary
      final overflowingShot = await tester.runAsync(() => screenshotter.capture(
        boundary: boundary,
        bounds: const Rect.fromLTWH(80, 80, 50, 50),
        pixelRatio: 1.0,
      ));

      expect(overflowingShot, isNotNull);
      expect(overflowingShot!.bytes, isNotEmpty);
    });
  });
}
