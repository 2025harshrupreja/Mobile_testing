import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/storage_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_analyzer_impl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => StorageProvider(StorageAnalyzerImpl()),
      child: const StorageAnalyzerApp(),
    ),
  );
}

class StorageAnalyzerApp extends StatelessWidget {
  const StorageAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
