import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:like/like.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:like_docs/app.dart';
import 'package:like_docs/like_app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock path provider
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      if (methodCall.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      if (methodCall.method == 'getApplicationSupportDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });

    // Mock connectivity
    const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (methodCall) async {
      if (methodCall.method == 'check') {
        return ['wifi'];
      }
      return null;
    });

    // Mock connectivity status event channel
    const connectivityStatusChannel = MethodChannel('dev.fluttercommunity.plus/connectivity_status');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (methodCall) async {
      if (methodCall.method == 'listen') {
        return null;
      }
      return null;
    });

    // Mock package info
    const packageInfoChannel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (methodCall) async {
      if (methodCall.method == 'getAll') {
        return {
          'appName': 'like_docs',
          'packageName': 'com.example.like_docs',
          'version': '1.0.0',
          'buildNumber': '1',
          'buildSignature': '',
        };
      }
      return null;
    });

    SharedPreferences.setMockInitialValues({});
    LikeConstants.apply(LikeConfig(
      connTimeout: Duration.zero,
      connCheckHost: '',
    ));
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
    await tester.runAsync(() async {
      await tester.pumpWidget(const LikeApp(child: LikeExampleApp()));
      await Future.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(LikeExampleApp), findsOneWidget);
  });
}
