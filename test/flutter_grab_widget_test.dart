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
}
