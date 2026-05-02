/// Represents a single file discovered by the scanner.
class FileItem {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String mimeType;
  final DateTime? dateModified;
  final String? sha256;

  const FileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.mimeType,
    this.dateModified,
    this.sha256,
  });

  factory FileItem.fromMap(Map<dynamic, dynamic> map) => FileItem(
        id: map['id'] as String,
        name: map['name'] as String,
        path: map['path'] as String,
        sizeBytes: (map['sizeBytes'] as num).toInt(),
        mimeType: map['mimeType'] as String? ?? '',
        dateModified: map['dateModifiedMs'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (map['dateModifiedMs'] as num).toInt())
            : null,
        sha256: map['sha256'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'path': path,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
        if (dateModified != null)
          'dateModifiedMs': dateModified!.millisecondsSinceEpoch,
        if (sha256 != null) 'sha256': sha256,
      };

  FileItem copyWith({String? sha256}) => FileItem(
        id: id,
        name: name,
        path: path,
        sizeBytes: sizeBytes,
        mimeType: mimeType,
        dateModified: dateModified,
        sha256: sha256 ?? this.sha256,
      );
}
