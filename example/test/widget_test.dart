import 'package:flutter_test/flutter_test.dart';
import 'package:scutari_core_example/main.dart';

void main() {
  testWidgets('Mounts ScutariCoreExampleApp safely', (WidgetTester tester) async {
    await tester.pumpWidget(const ScutariCoreExampleApp());
    expect(find.text('Scutari Core — Hardware Profiler'), findsOneWidget);
  });
}

