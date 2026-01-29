import 'package:flutter_test/flutter_test.dart';
import 'package:ensemble_tv/main.dart';

void main() {
  testWidgets('Ensemble TV app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EnsembleTVApp());

    // Verify that the app builds without crashing
    expect(find.byType(EnsembleTVApp), findsOneWidget);
  });
}
