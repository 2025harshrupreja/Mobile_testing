/// Storage usage for an installed application.
class AppStorageItem {
  final String packageName;
  final String appName;
  final int appBytes;
  final int dataBytes;
  final int cacheBytes;

  const AppStorageItem({
    required this.packageName,
    required this.appName,
    required this.appBytes,
    required this.dataBytes,
    required this.cacheBytes,
  });

  int get totalBytes => appBytes + dataBytes + cacheBytes;

  factory AppStorageItem.fromMap(Map<dynamic, dynamic> map) => AppStorageItem(
        packageName: map['packageName'] as String,
        appName: map['appName'] as String,
        appBytes: (map['appBytes'] as num).toInt(),
        dataBytes: (map['dataBytes'] as num).toInt(),
        cacheBytes: (map['cacheBytes'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'packageName': packageName,
        'appName': appName,
        'appBytes': appBytes,
        'dataBytes': dataBytes,
        'cacheBytes': cacheBytes,
      };
}
