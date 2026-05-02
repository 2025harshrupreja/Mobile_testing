import '../models/app_storage_item.dart';
import '../models/category_breakdown.dart';
import '../models/duplicate_group.dart';
import '../models/file_item.dart';
import '../models/storage_totals.dart';

/// Abstract interface for the storage analyzer.
abstract class StorageAnalyzer {
  /// Returns overall device storage totals.
  Future<StorageTotals> getStorageTotals();

  /// Returns per-category storage breakdowns.
  Future<List<CategoryBreakdown>> getCategoryBreakdowns();

  /// Returns the largest [topN] files found via MediaStore.
  Future<List<FileItem>> getLargeFiles({int topN = 50});

  /// Runs a two-pass duplicate scan:
  /// Pass 1 – group candidates by file size via MediaStore.
  /// Pass 2 – verify via SHA-256 hash for accessible items.
  Future<List<DuplicateGroup>> getDuplicates();

  /// Returns per-app storage info (requires PACKAGE_USAGE_STATS or
  /// StorageStatsManager; degrades gracefully when unavailable).
  Future<List<AppStorageItem>> getAppStorage();
}
