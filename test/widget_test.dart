import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:like/like.dart';
import 'package:like_docs/app.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_docs_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(LikeConstants.boxApiCache);
    await Hive.openBox(LikeConstants.boxCacheMetadata);
    await Hive.openBox(LikeConstants.boxEtags);
    await Hive.openBox(LikeConstants.boxOfflineQueue);

    // Register mock response for MealDB random endpoint using MockController
    final mocks = MockController();
    await mocks.addRule(
      MockRule(
        id: 'random_meal',
        pathPattern: 'https://www.themealdb.com/api/json/v1/1/random.php',
        method: 'GET',
        responseBody: '{"meals":[{"idMeal":"52954","strMeal":"Hot and Sour Soup","strCategory":"Pork","strArea":"Chinese","strInstructions":"Instructions","strMealThumb":"https://www.themealdb.com/images/media/meals/1529445893.jpg","strIngredient1":"Mushrooms","strMeasure1":"1/3 cup"}]}',
      ),
    );
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LikeExampleApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(LikeExampleApp), findsOneWidget);
  });
}
