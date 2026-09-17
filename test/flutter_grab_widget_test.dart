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

    // Verify AnimatedPositioned docks at top (top < 100)
    final animatedPositioned = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(animatedPositioned.top, lessThan(100));

    // Tap flip button
    await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
    await tester.pumpAndSettle();

    // Now it should be flipped to the bottom (top > 300)
    final flipped = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(flipped.top, greaterThan(300));
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
    expect(animatedPositioned.top, greaterThan(300));
  });

  testWidgets('GrabHud moves smoothly on vertical drag gesture', (tester) async {
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
    final initialTop = positioned.top!;
    expect(initialTop, greaterThan(300));

    // Drag up by 200px
    await tester.drag(find.text('AppBar'), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Now moved upwards
    positioned = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(positioned.top!, lessThan(initialTop));
  });

  testWidgets('GrabHud tucks to side in PiP mode and restores on tap', (tester) async {
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
    final candidate = WidgetCandidate(
      element: dummyElement,
      renderBox: dummyElement.renderObject as RenderBox?,
      bounds: const Rect.fromLTWH(50, 200, 200, 50),
      result: const GrabResult(
        widgetName: 'MetricCard',
        filePath: 'lib/metric.dart',
        line: 12,
      ),
    );

    controller.selectCandidate(candidate);
    await tester.pumpAndSettle();

    // Full card is visible with Grab Context button
    expect(find.text('Grab Context'), findsOneWidget);

    // Tap tuck button
    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    await tester.pumpAndSettle();

    // Full card buttons are collapsed, edge pill is visible
    expect(find.text('Grab Context'), findsNothing);
    expect(find.text('🎯'), findsOneWidget);

    // Tap edge pill to untuck
    await tester.tap(find.text('🎯'));
    await tester.pumpAndSettle();

    // Restored to full card
    expect(find.text('Grab Context'), findsOneWidget);
  });
}
