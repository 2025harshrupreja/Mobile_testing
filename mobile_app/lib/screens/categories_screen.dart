import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/storage_provider.dart';
import '../utils/format.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<StorageProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.isEmpty
          ? const Center(child: Text('No category data available.'))
          : ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  leading: _categoryIcon(cat.category),
                  title: Text(cat.category),
                  subtitle: Text('${cat.fileCount} files'),
                  trailing: Text(formatBytes(cat.totalBytes),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
    );
  }

  Widget _categoryIcon(String category) {
    final icons = {
      'Images': Icons.image,
      'Videos': Icons.videocam,
      'Audio': Icons.audiotrack,
      'Documents': Icons.description,
    };
    return Icon(icons[category] ?? Icons.folder);
  }
}
