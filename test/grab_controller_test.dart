import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grab/flutter_grab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GrabController', () {
    late GrabController controller;

    setUp(() {
      controller = GrabController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is inactive', () {
      expect(controller.isActive, isFalse);
      expect(controller.activeCandidate, isNull);
      expect(controller.hasCopied, isFalse);
    });

    test('toggleActive toggles state', () {
      controller.toggleActive();
      expect(controller.isActive, isTrue);

      controller.toggleActive();
      expect(controller.isActive, isFalse);
    });

    test('activate and deactivate work as expected', () {
      controller.activate();
      expect(controller.isActive, isTrue);

      controller.deactivate();
      expect(controller.isActive, isFalse);
    });

    testWidgets('copyActiveContext copies prompt to clipboard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test Target'),
            ),
          ),
        ),
      );

      final element = tester.element(find.text('Test Target'));
      final candidate = WidgetCandidate(
        element: element,
        renderBox: element.renderObject as RenderBox?,
        bounds: const Rect.fromLTWH(0, 0, 100, 50),
        result: const GrabResult(
          widgetName: 'Text',
          filePath: 'lib/test.dart',
          line: 10,
        ),
      );

      controller.activate();
      controller.selectCandidate(candidate);
      expect(controller.activeCandidate, candidate);

      // Track clipboard calls
      String? copiedClipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            copiedClipboardText = args['text'] as String?;
            return null;
          }
          return null;
        },
      );

      final success = await controller.copyActiveContext();
      expect(success, isTrue);
      expect(controller.hasCopied, isTrue);
      expect(copiedClipboardText, contains('Selected Widget: `Text`'));
      expect(copiedClipboardText, contains('lib/test.dart:10'));

      await tester.pump(const Duration(seconds: 3));
      expect(controller.hasCopied, isFalse);
    });

    testWidgets('multi-select batch queues widgets and copies combined prompt', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Target A'),
                Text('Target B'),
              ],
            ),
          ),
        ),
      );

      final elementA = tester.element(find.text('Target A'));
      final elementB = tester.element(find.text('Target B'));

      final candidateA = WidgetCandidate(
        element: elementA,
        renderBox: elementA.renderObject as RenderBox?,
        bounds: const Rect.fromLTWH(0, 0, 100, 30),
        result: const GrabResult(
          widgetName: 'TargetA',
          filePath: 'lib/a.dart',
          line: 15,
        ),
      );

      final candidateB = WidgetCandidate(
        element: elementB,
        renderBox: elementB.renderObject as RenderBox?,
        bounds: const Rect.fromLTWH(0, 40, 100, 30),
        result: const GrabResult(
          widgetName: 'TargetB',
          filePath: 'lib/b.dart',
          line: 25,
        ),
      );

      controller.activate();
      controller.toggleMultiSelectMode();
      expect(controller.isMultiSelectMode, isTrue);

      controller.selectCandidate(candidateA);
      controller.selectCandidate(candidateB);

      expect(controller.batchCandidates.length, 2);
      expect(controller.hasBatch, isTrue);

      String? copiedClipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            copiedClipboardText = args['text'] as String?;
            return null;
          }
          return null;
        },
      );

      final success = await controller.copyActiveContext();
      expect(success, isTrue);
      expect(copiedClipboardText, contains('Selected Widgets (2)'));
      expect(copiedClipboardText, contains('#### 1. `TargetA`'));
      expect(copiedClipboardText, contains('#### 2. `TargetB`'));

      controller.removeFromBatch(0);
      expect(controller.batchCandidates.length, 1);

      controller.clearBatch();
      expect(controller.batchCandidates.isEmpty, isTrue);
      expect(controller.isMultiSelectMode, isFalse);

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
