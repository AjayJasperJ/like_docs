import 'package:flutter_test/flutter_test.dart';
import 'package:like_docs/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LikeExampleApp());
    expect(find.byType(LikeExampleApp), findsOneWidget);
  });
}
