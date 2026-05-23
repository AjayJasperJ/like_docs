import 'package:like/like.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';

List<MealModel> mealListMapper(dynamic json) {
  if (json == null || json['meals'] == null) return const [];
  final list = json['meals'] as List<dynamic>;
  return list
      .map((item) => MealModel.fromJson(item as Map))
      .toList();
}

class MealRepository {
  final MealService _mealService;

  MealRepository(this._mealService);

  /// Fetches a random meal and maps it to a list of MealModels in a background isolate.
  Future<LikeApiResult<List<MealModel>>> getRandomMeal({ARS? ars}) async {
    return _mealService.fetchRandomMeal(ars: ars).mapAsync(mealListMapper);
  }

  /// Searches for meals and maps them to a list of MealModels in a background isolate.
  Future<LikeApiResult<List<MealModel>>> searchMeals(String query, {ARS? ars}) async {
    return _mealService.searchMeals(query, ars: ars).mapAsync(mealListMapper);
  }
}
