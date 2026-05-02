import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/file_item.dart';
import '../providers/storage_provider.dart';
import '../utils/format.dart';

class LargeFilesScreen extends StatelessWidget {
  const LargeFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final files = context.watch<StorageProvider>().largeFiles;

    return Scaffold(
      appBar: AppBar(title: const Text('Large Files')),
      body: files.isEmpty
          ? const Center(child: Text('No large files found.'))
          : ListView.separated(
              itemCount: files.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _FileRow(file: files[index]),
            ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final FileItem file;
  const _FileRow({required this.file});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(file.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(file.path, overflow: TextOverflow.ellipsis),
      trailing: Text(formatBytes(file.sizeBytes),
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
