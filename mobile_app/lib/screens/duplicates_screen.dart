import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/duplicate_group.dart';
import '../models/file_item.dart';
import '../providers/storage_provider.dart';
import '../utils/format.dart';

class DuplicatesScreen extends StatelessWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<StorageProvider>().duplicates;

    return Scaffold(
      appBar: AppBar(title: const Text('Duplicates')),
      body: groups.isEmpty
          ? const Center(child: Text('No duplicates found.'))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) =>
                  _DuplicateGroupCard(group: groups[index]),
            ),
    );
  }
}

class _DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;
  const _DuplicateGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.copy_all, color: Colors.orange),
        title: Text(
            '${group.items.length} copies · ${formatBytes(group.sizeBytes)} each'),
        subtitle: Text(
          'Wasted: ${formatBytes(group.wastedBytes)}'
          '${group.sha256 != null ? ' · SHA-256 verified' : ' · size match only'}',
        ),
        children: group.items
            .map((f) => _FileRow(file: f, groupSize: group.sizeBytes))
            .toList(),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final FileItem file;
  final int groupSize;
  const _FileRow({required this.file, required this.groupSize});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      leading: const Icon(Icons.insert_drive_file, size: 20),
      title: Text(file.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(file.path, overflow: TextOverflow.ellipsis),
    );
  }
}
