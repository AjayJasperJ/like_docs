import 'package:flutter/material.dart';
import 'package:like_docs/ui/custom_user_toast.dart';
import 'package:provider/provider.dart';
import 'package:like/like.dart';
import 'services/meal_service.dart';
import 'repositories/meal_repository.dart';
import 'providers/meal_provider.dart';
import 'ui/meal_screen.dart';

class LikeExampleApp extends StatefulWidget {
  const LikeExampleApp({super.key});

  @override
  State<LikeExampleApp> createState() => _LikeExampleAppState();
}

class _LikeExampleAppState extends State<LikeExampleApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //user custom desied toast ui and toast call contextless
      LikeToastType().showBespoke(
        title: 'App Launched Successfully',
        description: 'LIKE Enterprise Caching Engine active and ready.',
        icon: Icons.rocket_launch_rounded,
        iconColor: Colors.teal,
        backgroundColor: const Color(0xFFE8F5E9),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealService = MealService();
    final mealRepository = MealRepository(mealService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MealProvider(mealRepository)),
      ],
      child: MaterialApp(
        navigatorKey: Like.navigatorKey,
        title: 'LIKE Recipe Discovery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F8FC),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            surface: const Color(0xFFF7F8FC),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const MealScreen(),
      ),
    );
  }
}
