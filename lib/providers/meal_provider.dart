import 'package:flutter/foundation.dart';
import 'package:like/like.dart';
import '../models/meal_model.dart';
import '../repositories/meal_repository.dart';

class MealProvider with ChangeNotifier, LikeAutoReconnectMixin {
  final MealRepository _mealRepository;

  MealProvider(this._mealRepository);

  /// Managed state holding the random meal of the day.
  final randomMealState = LikeNotifierState<List<MealModel>>(
    mapper: (json) => mealListMapper(
      json,
    ), //if same api used in different provider it auto sync new data
  );

  /// Managed state holding user search results.
  final searchState = LikeNotifierState<List<MealModel>>(
    mapper: (json) => mealListMapper(
      json,
    ), //if same api used in different provider it auto sync new data
  );

  /// Safe state response getters consumed by the UI.
  LikeStateResponse<List<MealModel>> get randomMealResponse =>
      randomMealState.value;
  LikeStateResponse<List<MealModel>> get searchResponse => searchState.value;

  /// Fetches a random meal with full offline resiliency, SWR caching, and auto-resync.
  Future<LikeStateResponse<List<MealModel>>> fetchRandomMeal({ARS? ars}) async {
    return fetch<List<MealModel>>(
      state: randomMealState,
      ars: ars,
      autoResync: true,
      priority: LikeSyncPriority.normal,
      action: (ct, actionArs) async {
        final result = await _mealRepository.getRandomMeal(ars: actionArs);
        return result.toStateResponse();
      },
    );
  }

  /// Searches for meals using a query parameter with on-demand SWR fetching.
  Future<LikeStateResponse<List<MealModel>>> searchMeals(
    String query, {
    ARS? ars,
  }) async {
    return fetch<List<MealModel>>(
      state: searchState,
      ars: ars,
      autoResync: true,
      priority: LikeSyncPriority.normal,
      action: (ct, actionArs) async {
        final result = await _mealRepository.searchMeals(query, ars: actionArs);
        return result.toStateResponse();
      },
    );
  }
}
