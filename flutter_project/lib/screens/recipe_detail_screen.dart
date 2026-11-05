import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/recipe.dart';
import 'add_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipe = await DatabaseHelper.instance.getRecipeById(widget.recipeId);
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final recipe = _recipe;
    if (recipe == null || recipe.id == null) return;

    await DatabaseHelper.instance.updateFavoriteStatus(recipe.id!, !recipe.isFavorite);
    await _loadRecipe();
  }

  Future<void> _goToEditScreen() async {
    final recipe = _recipe;
    if (recipe == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecipeScreen(recipe: recipe),
      ),
    );

    if (changed == true) {
      await _loadRecipe();
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteRecipe() async {
    final recipe = _recipe;
    if (recipe == null || recipe.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DatabaseHelper.instance.deleteRecipe(recipe.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe deleted successfully.')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          IconButton(
            onPressed: recipe == null ? null : _toggleFavorite,
            icon: Icon(
              recipe?.isFavorite == true ? Icons.favorite : Icons.favorite_border,
              color: recipe?.isFavorite == true ? Colors.red : null,
            ),
            tooltip: 'Favorite',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipe == null
              ? const Center(child: Text('Recipe not found.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.category, size: 18),
                          label: Text(recipe.category),
                        ),
                        Chip(
                          avatar: const Icon(Icons.timer, size: 18),
                          label: Text('${recipe.cookingTime} min'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.bar_chart, size: 18),
                          label: Text(recipe.difficulty),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ingredients',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(recipe.ingredients),
                    const SizedBox(height: 20),
                    const Text(
                      'Preparation Instructions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(recipe.instructions),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _goToEditScreen,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deleteRecipe,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
