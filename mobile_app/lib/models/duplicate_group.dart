import 'file_item.dart';

/// A group of files that are likely duplicates (same size + hash).
class DuplicateGroup {
  final int sizeBytes;
  final String? sha256;
  final List<FileItem> items;

  const DuplicateGroup({
    required this.sizeBytes,
    this.sha256,
    required this.items,
  });

  /// Wasted bytes = all but one copy.
  int get wastedBytes => sizeBytes * (items.length - 1);

  factory DuplicateGroup.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>;
    return DuplicateGroup(
      sizeBytes: (map['sizeBytes'] as num).toInt(),
      sha256: map['sha256'] as String?,
      items: rawItems
          .map((e) => FileItem.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'sizeBytes': sizeBytes,
        if (sha256 != null) 'sha256': sha256,
        'items': items.map((f) => f.toMap()).toList(),
      };
}
