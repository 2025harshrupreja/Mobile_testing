import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_storage_item.dart';
import '../providers/storage_provider.dart';
import '../utils/format.dart';
import '../widgets/limitations_banner.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apps = context.watch<StorageProvider>().apps;

    return Scaffold(
      appBar: AppBar(title: const Text('Apps')),
      body: apps.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  LimitationsBanner(),
                  SizedBox(height: 24),
                  Center(
                      child: Text(
                          'App storage data unavailable.\n'
                          'PACKAGE_USAGE_STATS permission may be required.',
                          textAlign: TextAlign.center)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: apps.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _AppRow(app: apps[index]),
            ),
    );
  }
}

class _AppRow extends StatelessWidget {
  final AppStorageItem app;
  const _AppRow({required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.android),
      title: Text(app.appName),
      subtitle: Text('App: ${formatBytes(app.appBytes)} '
          '· Data: ${formatBytes(app.dataBytes)} '
          '· Cache: ${formatBytes(app.cacheBytes)}'),
      trailing: Text(formatBytes(app.totalBytes),
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
