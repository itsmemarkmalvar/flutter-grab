import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('GrabDemoApp builds and displays dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const GrabDemoApp());

    expect(find.text('Flutter Grab Demo'), findsOneWidget);
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Alex Rivers'), findsOneWidget);
    expect(find.text('Grab'), findsOneWidget);
  });
}
