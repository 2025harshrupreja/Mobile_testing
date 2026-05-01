import 'package:flutter/foundation.dart';

import '../models/app_storage_item.dart';
import '../models/category_breakdown.dart';
import '../models/duplicate_group.dart';
import '../models/file_item.dart';
import '../models/storage_totals.dart';
import '../services/storage_analyzer.dart';

enum LoadState { idle, loading, loaded, error }

/// Central state holder for all storage scan data.
class StorageProvider extends ChangeNotifier {
  final StorageAnalyzer _analyzer;

  StorageProvider(this._analyzer);

  LoadState _state = LoadState.idle;
  LoadState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StorageTotals? _totals;
  StorageTotals? get totals => _totals;

  List<CategoryBreakdown> _categories = [];
  List<CategoryBreakdown> get categories => _categories;

  List<FileItem> _largeFiles = [];
  List<FileItem> get largeFiles => _largeFiles;

  List<DuplicateGroup> _duplicates = [];
  List<DuplicateGroup> get duplicates => _duplicates;

  List<AppStorageItem> _apps = [];
  List<AppStorageItem> get apps => _apps;

  /// Kick off a full scan (all data sources in parallel).
  Future<void> refresh() async {
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _analyzer.getStorageTotals(),
        _analyzer.getCategoryBreakdowns(),
        _analyzer.getLargeFiles(),
        _analyzer.getDuplicates(),
        _analyzer.getAppStorage(),
      ]);

      _totals = results[0] as StorageTotals;
      _categories = results[1] as List<CategoryBreakdown>;
      _largeFiles = results[2] as List<FileItem>;
      _duplicates = results[3] as List<DuplicateGroup>;
      _apps = results[4] as List<AppStorageItem>;

      _state = LoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoadState.error;
    }

    notifyListeners();
  }
}
