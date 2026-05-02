import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/duplicate_group.dart';
import 'package:mobile_app/models/file_item.dart';

/// Helper: simulate pass-1 grouping by size.
Map<int, List<FileItem>> groupBySize(List<FileItem> files) {
  final map = <int, List<FileItem>>{};
  for (final f in files) {
    map.putIfAbsent(f.sizeBytes, () => []).add(f);
  }
  return map;
}

/// Helper: simulate pass-2 grouping by sha256 within same-size candidates.
List<DuplicateGroup> groupByHash(Map<int, List<FileItem>> sizeGroups) {
  final groups = <DuplicateGroup>[];
  for (final entry in sizeGroups.entries) {
    final candidates = entry.value;
    if (candidates.length < 2) continue;
    final byHash = <String, List<FileItem>>{};
    for (final f in candidates) {
      final key = f.sha256 ?? '__no_hash_${entry.key}';
      byHash.putIfAbsent(key, () => []).add(f);
    }
    for (final hashEntry in byHash.entries) {
      if (hashEntry.value.length < 2) continue;
      groups.add(DuplicateGroup(
        sizeBytes: entry.key,
        sha256: hashEntry.key.startsWith('__no_hash_') ? null : hashEntry.key,
        items: hashEntry.value,
      ));
    }
  }
  return groups;
}

void main() {
  group('Two-pass duplicate grouping', () {
    FileItem makeFile(String id, String name, int size, {String? hash}) =>
        FileItem(
          id: id,
          name: name,
          path: '/sdcard/$name',
          sizeBytes: size,
          mimeType: 'application/octet-stream',
          sha256: hash,
        );

    test('groups files with same size and same hash as duplicates', () {
      final files = [
        makeFile('1', 'a.bin', 1000, hash: 'abc'),
        makeFile('2', 'b.bin', 1000, hash: 'abc'),
        makeFile('3', 'c.bin', 2000, hash: 'def'),
      ];
      final bySize = groupBySize(files);
      final groups = groupByHash(bySize);
      expect(groups.length, 1);
      expect(groups.first.items.length, 2);
      expect(groups.first.sha256, 'abc');
    });

    test('does not group files with same size but different hash', () {
      final files = [
        makeFile('1', 'a.bin', 1000, hash: 'aaa'),
        makeFile('2', 'b.bin', 1000, hash: 'bbb'),
      ];
      final bySize = groupBySize(files);
      final groups = groupByHash(bySize);
      expect(groups, isEmpty);
    });

    test('falls back to size-only grouping when no hash available', () {
      final files = [
        makeFile('1', 'a.bin', 999),
        makeFile('2', 'b.bin', 999),
      ];
      final bySize = groupBySize(files);
      final groups = groupByHash(bySize);
      expect(groups.length, 1);
      expect(groups.first.sha256, isNull);
      expect(groups.first.wastedBytes, 999);
    });

    test('unique-size files are never flagged as duplicates', () {
      final files = [
        makeFile('1', 'x.bin', 100, hash: 'h1'),
        makeFile('2', 'y.bin', 200, hash: 'h2'),
        makeFile('3', 'z.bin', 300, hash: 'h3'),
      ];
      final bySize = groupBySize(files);
      final groups = groupByHash(bySize);
      expect(groups, isEmpty);
    });

    test('handles three copies correctly, wastedBytes = size * (n-1)', () {
      final files = [
        makeFile('1', 'a.bin', 500, hash: 'same'),
        makeFile('2', 'b.bin', 500, hash: 'same'),
        makeFile('3', 'c.bin', 500, hash: 'same'),
      ];
      final bySize = groupBySize(files);
      final groups = groupByHash(bySize);
      expect(groups.length, 1);
      expect(groups.first.items.length, 3);
      expect(groups.first.wastedBytes, 1000); // 500 * (3-1)
    });
  });
}
