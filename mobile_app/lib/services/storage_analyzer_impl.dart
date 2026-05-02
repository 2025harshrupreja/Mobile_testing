import 'package:flutter/services.dart';

import '../models/app_storage_item.dart';
import '../models/category_breakdown.dart';
import '../models/duplicate_group.dart';
import '../models/file_item.dart';
import '../models/storage_totals.dart';
import 'storage_analyzer.dart';

/// MethodChannel-backed implementation of [StorageAnalyzer].
/// All heavy work runs in Kotlin on the Android side.
class StorageAnalyzerImpl implements StorageAnalyzer {
  static const _channel = MethodChannel('storage_analyzer');

  @override
  Future<StorageTotals> getStorageTotals() async {
    final result = await _channel.invokeMethod<Map>('getStorageTotals');
    return StorageTotals.fromMap(result!);
  }

  @override
  Future<List<CategoryBreakdown>> getCategoryBreakdowns() async {
    final result =
        await _channel.invokeMethod<List>('getCategoryBreakdowns');
    return (result ?? [])
        .map((e) => CategoryBreakdown.fromMap(e as Map))
        .toList();
  }

  @override
  Future<List<FileItem>> getLargeFiles({int topN = 50}) async {
    final result =
        await _channel.invokeMethod<List>('getLargeFiles', {'topN': topN});
    return (result ?? []).map((e) => FileItem.fromMap(e as Map)).toList();
  }

  @override
  Future<List<DuplicateGroup>> getDuplicates() async {
    final result = await _channel.invokeMethod<List>('getDuplicates');
    return (result ?? [])
        .map((e) => DuplicateGroup.fromMap(e as Map))
        .toList();
  }

  @override
  Future<List<AppStorageItem>> getAppStorage() async {
    final result = await _channel.invokeMethod<List>('getAppStorage');
    return (result ?? [])
        .map((e) => AppStorageItem.fromMap(e as Map))
        .toList();
  }
}
