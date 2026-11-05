import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/recipe.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddRecipeScreen({super.key, this.recipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _cookingTimeController = TextEditingController();

  final List<String> _categories = const [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snacks',
  ];
  final List<String> _difficulties = const ['Easy', 'Medium', 'Hard'];

  String _selectedCategory = 'Breakfast';
  String _selectedDifficulty = 'Easy';
  bool _isSaving = false;

  bool get _isEditMode => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    if (recipe != null) {
      _nameController.text = recipe.name;
      _ingredientsController.text = recipe.ingredients;
      _instructionsController.text = recipe.instructions;
      _cookingTimeController.text = recipe.cookingTime.toString();
      _selectedCategory = recipe.category;
      _selectedDifficulty = recipe.difficulty;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _cookingTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final existing = widget.recipe;
    final recipe = Recipe(
      id: existing?.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      ingredients: _ingredientsController.text.trim(),
      instructions: _instructionsController.text.trim(),
      cookingTime: int.parse(_cookingTimeController.text.trim()),
      difficulty: _selectedDifficulty,
      isFavorite: existing?.isFavorite ?? false,
    );

    try {
      if (_isEditMode) {
        await DatabaseHelper.instance.updateRecipe(recipe);
      } else {
        await DatabaseHelper.instance.insertRecipe(recipe);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Recipe updated successfully.' : 'Recipe added successfully.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Recipe' : 'Add Recipe'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Recipe name is required.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredients',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingredients are required.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Preparation Instructions',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 6,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Instructions are required.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cookingTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cooking Time (minutes)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cooking time is required.';
                }
                final minutes = int.tryParse(value.trim());
                if (minutes == null || minutes <= 0) {
                  return 'Enter a valid positive number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
              ),
              items: _difficulties
                  .map((difficulty) => DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedDifficulty = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveRecipe,
              icon: const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Recipe'),
            ),
          ],
        ),
      ),
    );
  }
}
