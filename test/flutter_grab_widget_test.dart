import 'package:flutter/material.dart';
import 'package:flutter_grab/flutter_grab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlutterGrab renders child and floating trigger', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlutterGrab(
          child: Scaffold(
            body: Center(
              child: Text('My App Content'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('My App Content'), findsOneWidget);
    expect(find.text('Grab'), findsOneWidget);
  });

  testWidgets('Tapping floating trigger activates Grab mode', (tester) async {
    final controller = GrabController();

    await tester.pumpWidget(
      MaterialApp(
        home: FlutterGrab(
          controller: controller,
          child: const Scaffold(
            body: Center(
              child: Text('Inspectable Button'),
            ),
          ),
        ),
      ),
    );

    expect(controller.isActive, isFalse);

    // Tap the Grab trigger button
    await tester.tap(find.text('Grab'));
    await tester.pump();

    expect(controller.isActive, isTrue);
    expect(find.text('Grabbing'), findsOneWidget);

    // Tap it again to deactivate
    await tester.tap(find.text('Grabbing'));
    await tester.pump();

    expect(controller.isActive, isFalse);
    expect(find.text('Grab'), findsOneWidget);
  });

  testWidgets('FlutterGrab.builder integrates cleanly with MaterialApp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterGrab.builder,
        home: const Scaffold(
          body: Center(
            child: Text('Inside Builder'),
          ),
        ),
      ),
    );

    expect(find.text('Inside Builder'), findsOneWidget);
    expect(find.text('Grab'), findsOneWidget);
  });

  testWidgets('GrabHud adapts to top when target widget is in lower half', (tester) async {
    final controller = GrabController();

    await tester.pumpWidget(
      MaterialApp(
        home: FlutterGrab(
          controller: controller,
          child: const Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      ),
    );

    controller.activate();
    await tester.pump();

    // Target at the bottom (y = 550 on default 800x600 canvas)
    final dummyElement = tester.element(find.byType(Scaffold));
    final candidateBottom = WidgetCandidate(
      element: dummyElement,
      renderBox: dummyElement.renderObject as RenderBox?,
      bounds: const Rect.fromLTWH(50, 550, 200, 50),
      result: const GrabResult(
        widgetName: 'BottomNavigationBar',
        filePath: 'lib/nav.dart',
        line: 20,
      ),
    );

    controller.selectCandidate(candidateBottom);
    await tester.pumpAndSettle();

    expect(find.text('BottomNavigationBar'), findsOneWidget);
    expect(find.text('Grab Context'), findsOneWidget);

    // Verify AnimatedPositioned has top != null and bottom == null
    final animatedPositioned = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(animatedPositioned.top, isNotNull);
    expect(animatedPositioned.bottom, isNull);

    // Tap flip button
    await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
    await tester.pumpAndSettle();

    // Now it should be flipped to the bottom
    final flipped = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(flipped.top, isNull);
    expect(flipped.bottom, isNotNull);
  });

  testWidgets('GrabHud docks at bottom when target widget is in top half', (tester) async {
    final controller = GrabController();

    await tester.pumpWidget(
      MaterialApp(
        home: FlutterGrab(
          controller: controller,
          child: const Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      ),
    );

    controller.activate();
    await tester.pump();

    final dummyElement = tester.element(find.byType(Scaffold));
    final candidateTop = WidgetCandidate(
      element: dummyElement,
      renderBox: dummyElement.renderObject as RenderBox?,
      bounds: const Rect.fromLTWH(50, 50, 200, 50),
      result: const GrabResult(
        widgetName: 'AppBarTitle',
        filePath: 'lib/app_bar.dart',
        line: 10,
      ),
    );

    controller.selectCandidate(candidateTop);
    await tester.pumpAndSettle();

    final animatedPositioned = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(animatedPositioned.top, isNull);
    expect(animatedPositioned.bottom, isNotNull);
  });

  testWidgets('GrabHud flips position on vertical swipe gesture', (tester) async {
    final controller = GrabController();

    await tester.pumpWidget(
      MaterialApp(
        home: FlutterGrab(
          controller: controller,
          child: const Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      ),
    );

    controller.activate();
    await tester.pump();

    // Target at top -> HUD at bottom
    final dummyElement = tester.element(find.byType(Scaffold));
    final candidate = WidgetCandidate(
      element: dummyElement,
      renderBox: dummyElement.renderObject as RenderBox?,
      bounds: const Rect.fromLTWH(50, 50, 200, 50),
      result: const GrabResult(
        widgetName: 'AppBar',
        filePath: 'lib/app_bar.dart',
        line: 10,
      ),
    );

    controller.selectCandidate(candidate);
    await tester.pumpAndSettle();

    // Initially at bottom
    var positioned = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(positioned.top, isNull);
    expect(positioned.bottom, isNotNull);

    // Swipe up on HUD
    await tester.fling(find.text('AppBar'), const Offset(0, -500), 1000);
    await tester.pumpAndSettle();

    // Now moved to top
    positioned = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(positioned.top, isNotNull);
    expect(positioned.bottom, isNull);

    // Swipe down on HUD
    await tester.fling(find.text('AppBar'), const Offset(0, 500), 1000);
    await tester.pumpAndSettle();

    // Back to bottom
    positioned = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(positioned.top, isNull);
    expect(positioned.bottom, isNotNull);
  });
}
