import 'package:like/like.dart';

class MealService {
  /// Fetches a single random meal from the MealDB API.
  Future<LikeApiResult<Response>> fetchRandomMeal({ARS? ars}) {
    return LikeClient().get(
      'https://www.themealdb.com/api/json/v1/1/random.php',
      ars: ars,
    );
  }

  /// Searches for meals matching the query string.
  Future<LikeApiResult<Response>> searchMeals(String query, {ARS? ars}) {
    final encodedQuery = Uri.encodeComponent(query);
    return LikeClient().get(
      'https://www.themealdb.com/api/json/v1/1/search.php?s=$encodedQuery',
      ars: ars,
    );
  }
}
