/// Storage usage breakdown for a category (Images, Videos, Audio, Documents).
class CategoryBreakdown {
  final String category;
  final int fileCount;
  final int totalBytes;

  const CategoryBreakdown({
    required this.category,
    required this.fileCount,
    required this.totalBytes,
  });

  factory CategoryBreakdown.fromMap(Map<dynamic, dynamic> map) =>
      CategoryBreakdown(
        category: map['category'] as String,
        fileCount: (map['fileCount'] as num).toInt(),
        totalBytes: (map['totalBytes'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'category': category,
        'fileCount': fileCount,
        'totalBytes': totalBytes,
      };
}
