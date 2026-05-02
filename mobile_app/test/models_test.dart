import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/storage_totals.dart';
import 'package:mobile_app/models/category_breakdown.dart';
import 'package:mobile_app/models/file_item.dart';
import 'package:mobile_app/models/duplicate_group.dart';
import 'package:mobile_app/models/app_storage_item.dart';

void main() {
  group('StorageTotals', () {
    test('fromMap computes usedBytes correctly', () {
      final totals = StorageTotals.fromMap({
        'totalBytes': 100,
        'freeBytes': 40,
      });
      expect(totals.totalBytes, 100);
      expect(totals.freeBytes, 40);
      expect(totals.usedBytes, 60);
    });

    test('toMap round-trips', () {
      const totals = StorageTotals(
        totalBytes: 200,
        freeBytes: 80,
        usedBytes: 120,
      );
      final map = totals.toMap();
      expect(map['totalBytes'], 200);
      expect(map['freeBytes'], 80);
      expect(map['usedBytes'], 120);
    });
  });

  group('CategoryBreakdown', () {
    test('fromMap parses correctly', () {
      final cat = CategoryBreakdown.fromMap({
        'category': 'Images',
        'fileCount': 42,
        'totalBytes': 1024,
      });
      expect(cat.category, 'Images');
      expect(cat.fileCount, 42);
      expect(cat.totalBytes, 1024);
    });

    test('toMap round-trips', () {
      const cat = CategoryBreakdown(
        category: 'Videos',
        fileCount: 10,
        totalBytes: 512,
      );
      final map = cat.toMap();
      expect(map['category'], 'Videos');
      expect(map['fileCount'], 10);
      expect(map['totalBytes'], 512);
    });
  });

  group('FileItem', () {
    test('fromMap handles optional fields', () {
      final item = FileItem.fromMap({
        'id': '1',
        'name': 'photo.jpg',
        'path': '/sdcard/photo.jpg',
        'sizeBytes': 2048,
        'mimeType': 'image/jpeg',
        'dateModifiedMs': 1700000000000,
      });
      expect(item.id, '1');
      expect(item.name, 'photo.jpg');
      expect(item.sizeBytes, 2048);
      expect(item.sha256, isNull);
      expect(item.dateModified, isNotNull);
    });

    test('copyWith replaces sha256', () {
      final item = FileItem.fromMap({
        'id': '2',
        'name': 'doc.pdf',
        'path': '/sdcard/doc.pdf',
        'sizeBytes': 512,
        'mimeType': 'application/pdf',
      });
      final updated = item.copyWith(sha256: 'abc123');
      expect(updated.sha256, 'abc123');
      expect(updated.name, 'doc.pdf');
    });
  });

  group('DuplicateGroup', () {
    final rawItems = [
      {
        'id': 'a',
        'name': 'a.mp3',
        'path': '/a.mp3',
        'sizeBytes': 1000,
        'mimeType': 'audio/mpeg',
      },
      {
        'id': 'b',
        'name': 'b.mp3',
        'path': '/b.mp3',
        'sizeBytes': 1000,
        'mimeType': 'audio/mpeg',
      },
    ];

    test('fromMap parses items and computes wastedBytes', () {
      final group = DuplicateGroup.fromMap({
        'sizeBytes': 1000,
        'sha256': 'deadbeef',
        'items': rawItems,
      });
      expect(group.items.length, 2);
      expect(group.wastedBytes, 1000); // 1000 * (2 - 1)
    });

    test('wastedBytes scales with item count', () {
      final group = DuplicateGroup.fromMap({
        'sizeBytes': 500,
        'items': [
          ...rawItems,
          {
            'id': 'c',
            'name': 'c.mp3',
            'path': '/c.mp3',
            'sizeBytes': 500,
            'mimeType': 'audio/mpeg',
          }
        ],
      });
      expect(group.items.length, 3);
      expect(group.wastedBytes, 1000); // 500 * (3 - 1)
    });
  });

  group('AppStorageItem', () {
    test('fromMap parses and totalBytes sums correctly', () {
      final app = AppStorageItem.fromMap({
        'packageName': 'com.example.app',
        'appName': 'Example',
        'appBytes': 10,
        'dataBytes': 20,
        'cacheBytes': 5,
      });
      expect(app.totalBytes, 35);
    });

    test('toMap round-trips', () {
      const app = AppStorageItem(
        packageName: 'com.test',
        appName: 'Test',
        appBytes: 1,
        dataBytes: 2,
        cacheBytes: 3,
      );
      final map = app.toMap();
      expect(map['packageName'], 'com.test');
      expect(map['cacheBytes'], 3);
    });
  });
}
