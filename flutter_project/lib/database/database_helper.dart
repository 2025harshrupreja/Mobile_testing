import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recipe.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recipe_book.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        cooking_time INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Insert starter data so the app is easy to demo after first install.
    await db.insert('recipes', {
      'name': 'Vegetable Poha',
      'category': 'Breakfast',
      'ingredients': 'Poha, onion, peas, turmeric, lemon, salt',
      'instructions':
          'Rinse poha. Saute onion and peas, add spices, then mix poha and cook for 3-4 minutes.',
      'cooking_time': 15,
      'difficulty': 'Easy',
      'is_favorite': 1,
    });

    await db.insert('recipes', {
      'name': 'Paneer Butter Masala',
      'category': 'Dinner',
      'ingredients': 'Paneer, tomato puree, onion, cream, butter, spices',
      'instructions':
          'Cook onion-tomato gravy with spices, blend, add paneer cubes and cream, simmer well.',
      'cooking_time': 35,
      'difficulty': 'Medium',
      'is_favorite': 0,
    });

    await db.insert('recipes', {
      'name': 'Fruit Custard',
      'category': 'Dessert',
      'ingredients': 'Milk, custard powder, sugar, mixed fruits',
      'instructions':
          'Prepare custard in milk, cool it completely, then mix chopped fruits before serving.',
      'cooking_time': 20,
      'difficulty': 'Easy',
      'is_favorite': 0,
    });
  }

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await database;
    return db.insert('recipes', recipe.toMap()..remove('id'));
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final maps = await db.query('recipes', orderBy: 'name COLLATE NOCASE ASC');
    return maps.map(Recipe.fromMap).toList();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await database;
    final maps = await db.query('recipes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Recipe.fromMap(maps.first);
  }

  Future<List<Recipe>> searchAndFilterRecipes({
    String searchQuery = '',
    String? category,
    bool favoritesOnly = false,
  }) async {
    final db = await database;
    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery.trim().isNotEmpty) {
      whereParts.add('name LIKE ?');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (category != null && category != 'All') {
      whereParts.add('category = ?');
      whereArgs.add(category);
    }

    if (favoritesOnly) {
      whereParts.add('is_favorite = 1');
    }

    final maps = await db.query(
      'recipes',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return maps.map(Recipe.fromMap).toList();
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return db.update(
      'recipes',
      recipe.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await database;
    return db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateFavoriteStatus(int id, bool isFavorite) async {
    final db = await database;
    return db.update(
      'recipes',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
