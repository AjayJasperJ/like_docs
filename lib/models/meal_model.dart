class MealModel {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String thumbUrl;
  final String? youtubeUrl;

  MealModel({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.thumbUrl,
    this.youtubeUrl,
  });

  factory MealModel.fromJson(Map<dynamic, dynamic> json) {
    return MealModel(
      id: json['idMeal'] as String? ?? '',
      name: json['strMeal'] as String? ?? '',
      category: json['strCategory'] as String? ?? '',
      area: json['strArea'] as String? ?? '',
      instructions: json['strInstructions'] as String? ?? '',
      thumbUrl: json['strMealThumb'] as String? ?? '',
      youtubeUrl: json['strYoutube'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'idMeal': id,
    'strMeal': name,
    'strCategory': category,
    'strArea': area,
    'strInstructions': instructions,
    'strMealThumb': thumbUrl,
    'strYoutube': youtubeUrl,
  };
}
