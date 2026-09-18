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

      expect(output, contains('### 🎯 Flutter Grab (2 Widgets)'));
      expect(output, contains('1. `ProfileCard` → `lib/features/profile/profile_card.dart:42:15`'));
      expect(output, contains('2. `RecentActivity` → `lib/features/dashboard/recent_activity.dart:88:10`'));
      expect(output, contains('Hierarchy: `DashboardScreen > RecentActivity`'));
    });

    test('formats markdown with screenshotBase64 correctly', () {
      final shotResult = sampleResult.copyWith(
        screenshotBase64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );
      const formatter = AiPromptFormatter(includeScreenshot: true);
      final output = formatter.format(shotResult);

      expect(output, contains('#### 📸 Visual Snapshot (Base64 PNG)'));
      expect(output, contains('<details open>'));
      expect(output, contains('<img src="data:image/png;base64,iVBORw0KGgoAAA'));
    });

    test('formats markdown with screenshotPath correctly without base64 bloat', () {
      final shotResult = sampleResult.copyWith(
        screenshotPath: '/tmp/flutter_grab/ProfileCard.png',
      );
      const formatter = AiPromptFormatter();
      final output = formatter.format(shotResult);

      expect(output, contains('- **📸 Screenshot:** `file:///tmp/flutter_grab/ProfileCard.png`'));
      expect(output, contains('A visual screenshot is saved at `file:///tmp/flutter_grab/ProfileCard.png`.'));
      expect(output, isNot(contains('Base64')));
    });

    test('formats multi-markdown with screenshotPath correctly', () {
      final r1 = sampleResult.copyWith(screenshotPath: '/tmp/flutter_grab/ProfileCard.png');
      final r2 = GrabResult(
        widgetName: 'RecentActivity',
        filePath: 'lib/features/dashboard/recent_activity.dart',
        line: 88,
        column: 10,
        screenshotPath: '/tmp/flutter_grab/RecentActivity.png',
      );
      const formatter = AiPromptFormatter();
      final output = formatter.formatMultiple([r1, r2]);

      expect(output, contains('Screenshot: `file:///tmp/flutter_grab/ProfileCard.png`'));
      expect(output, contains('Screenshot: `file:///tmp/flutter_grab/RecentActivity.png`'));
    });

    test('formats XML with screenshotPath correctly', () {
      final shotResult = sampleResult.copyWith(
        screenshotPath: '/tmp/flutter_grab/ProfileCard.png',
      );
      const formatter = AiPromptFormatter(style: PromptFormatStyle.xml);
      final output = formatter.format(shotResult);

      expect(output, contains('<screenshot_path>/tmp/flutter_grab/ProfileCard.png</screenshot_path>'));
    });
  });
}
