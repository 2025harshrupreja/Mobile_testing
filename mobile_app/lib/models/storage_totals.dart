/// Overall device storage totals.
class StorageTotals {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;

  const StorageTotals({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
  });

  factory StorageTotals.fromMap(Map<dynamic, dynamic> map) {
    final total = (map['totalBytes'] as num).toInt();
    final free = (map['freeBytes'] as num).toInt();
    return StorageTotals(
      totalBytes: total,
      freeBytes: free,
      usedBytes: total - free,
    );
  }

  Map<String, int> toMap() => {
        'totalBytes': totalBytes,
        'freeBytes': freeBytes,
        'usedBytes': usedBytes,
      };
}
