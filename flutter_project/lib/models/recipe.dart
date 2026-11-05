class Recipe {
  final int? id;
  final String name;
  final String category;
  final String ingredients;
  final String instructions;
  final int cookingTime;
  final String difficulty;
  final bool isFavorite;

  const Recipe({
    this.id,
    required this.name,
    required this.category,
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.difficulty,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'ingredients': ingredients,
      'instructions': instructions,
      'cooking_time': cookingTime,
      'difficulty': difficulty,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      ingredients: map['ingredients'] as String,
      instructions: map['instructions'] as String,
      cookingTime: map['cooking_time'] as int,
      difficulty: map['difficulty'] as String,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }

  Recipe copyWith({
    int? id,
    String? name,
    String? category,
    String? ingredients,
    String? instructions,
    int? cookingTime,
    String? difficulty,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      cookingTime: cookingTime ?? this.cookingTime,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
