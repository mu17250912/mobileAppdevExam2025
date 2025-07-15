import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/main.dart';

void main() {
  testWidgets('SkillSwap app starts and shows splash screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const SkillSwapApp());

    // Verify that our splash screen shows the correct content
    expect(find.text('SkillSwap'), findsOneWidget);
    expect(find.text('Learn. Share. Grow.'), findsOneWidget);
  });
}
