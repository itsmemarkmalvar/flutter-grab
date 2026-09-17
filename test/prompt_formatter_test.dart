import 'package:flutter/widgets.dart';
import 'package:flutter_grab/flutter_grab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiPromptFormatter', () {
    const sampleResult = GrabResult(
      widgetName: 'ProfileCard',
      filePath: 'lib/features/profile/profile_card.dart',
      line: 42,
      column: 15,
      isLocalProject: true,
      ancestry: ['HomeScreen', 'ProfileSection', 'ProfileCard'],
      bounds: Rect.fromLTWH(20, 50, 300, 80),
    );

    test('formats markdown correctly with all fields', () {
      const formatter = AiPromptFormatter(style: PromptFormatStyle.markdown);
      final output = formatter.format(sampleResult);

      expect(output, contains('<!-- Flutter Grab Context -->'));
      expect(output, contains('### 🎯 Selected Widget: `ProfileCard`'));
      expect(output, contains('- **Source File:** `lib/features/profile/profile_card.dart:42:15`'));
      expect(output, contains('- **Widget Hierarchy:** `HomeScreen > ProfileSection > ProfileCard`'));
      expect(output, contains('- **Render Size:** `300.0 x 80.0`'));
      expect(output, contains('> **Note for AI:**'));
    });

    test('formats XML correctly', () {
      const formatter = AiPromptFormatter(style: PromptFormatStyle.xml);
      final output = formatter.format(sampleResult);

      expect(output, contains('<flutter_grab_context>'));
      expect(output, contains('<widget>ProfileCard</widget>'));
      expect(output, contains('<file>lib/features/profile/profile_card.dart</file>'));
      expect(output, contains('<line>42</line>'));
      expect(output, contains('<column>15</column>'));
      expect(output, contains('<ancestry>HomeScreen > ProfileSection > ProfileCard</ancestry>'));
      expect(output, contains('<dimensions>300.0 x 80.0</dimensions>'));
      expect(output, contains('</flutter_grab_context>'));
    });

    test('formats compact format correctly', () {
      const formatter = AiPromptFormatter(style: PromptFormatStyle.compact);
      final output = formatter.format(sampleResult);

      expect(output, contains('name="ProfileCard"'));
      expect(output, contains('file="lib/features/profile/profile_card.dart"'));
      expect(output, contains('line="42"'));
      expect(output, contains('col="15"'));
      expect(output, contains('ancestry="HomeScreen > ProfileSection > ProfileCard"'));
      expect(output, contains('size="300.0 x 80.0"'));
    });

    test('handles missing file and bounds gracefully', () {
      const minimalResult = GrabResult(
        widgetName: 'AnonymousWidget',
      );
      const formatter = AiPromptFormatter();
      final output = formatter.format(minimalResult);

      expect(output, contains('### 🎯 Selected Widget: `AnonymousWidget`'));
      expect(output, contains('unknown location'));
      expect(output, isNot(contains('- **Size:**')));
    });

    test('formatMultiple formats multiple widgets into single prompt', () {
      const secondResult = GrabResult(
        widgetName: 'RecentActivity',
        filePath: 'lib/features/dashboard/recent_activity.dart',
        line: 88,
        column: 10,
        ancestry: ['DashboardScreen', 'RecentActivity'],
      );

      const formatter = AiPromptFormatter();
      final output = formatter.formatMultiple([sampleResult, secondResult]);

      expect(output, contains('### 🎯 Selected Widgets (2)'));
      expect(output, contains('#### 1. `ProfileCard`'));
      expect(output, contains('lib/features/profile/profile_card.dart:42:15'));
      expect(output, contains('#### 2. `RecentActivity`'));
      expect(output, contains('lib/features/dashboard/recent_activity.dart:88:10'));
      expect(output, contains('The user selected these 2 widgets on screen together.'));
    });
  });
}
