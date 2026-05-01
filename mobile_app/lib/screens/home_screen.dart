import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/storage_totals.dart';
import '../providers/storage_provider.dart';
import '../widgets/bytes_text.dart';
import '../widgets/limitations_banner.dart';
import 'apps_screen.dart';
import 'categories_screen.dart';
import 'duplicates_screen.dart';
import 'large_files_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StorageProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StorageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                provider.state == LoadState.loading ? null : provider.refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(StorageProvider provider) {
    if (provider.state == LoadState.idle) {
      return const Center(child: Text('Tap refresh to scan storage.'));
    }
    if (provider.state == LoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.state == LoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: provider.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final totals = provider.totals;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LimitationsBanner(),
          const SizedBox(height: 12),
          if (totals != null) ...[
            _StorageGaugeCard(totals: totals),
            const SizedBox(height: 16),
          ],
          _DashboardGrid(provider: provider),
        ],
      ),
    );
  }
}

class _StorageGaugeCard extends StatelessWidget {
  final StorageTotals totals;
  const _StorageGaugeCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final used = totals.usedBytes;
    final total = totals.totalBytes;
    final fraction = total > 0 ? used / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Storage',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BytesText(bytes: used, label: 'Used'),
                BytesText(bytes: totals.freeBytes as int, label: 'Free'),
                BytesText(bytes: total, label: 'Total'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final StorageProvider provider;
  const _DashboardGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _DashTile(
          icon: Icons.category,
          label: 'Categories',
          subtitle: '${provider.categories.length} types',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen())),
        ),
        _DashTile(
          icon: Icons.insert_drive_file,
          label: 'Large Files',
          subtitle: '${provider.largeFiles.length} files',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LargeFilesScreen())),
        ),
        _DashTile(
          icon: Icons.copy_all,
          label: 'Duplicates',
          subtitle: '${provider.duplicates.length} groups',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DuplicatesScreen())),
        ),
        _DashTile(
          icon: Icons.apps,
          label: 'Apps',
          subtitle: '${provider.apps.length} apps',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AppsScreen())),
        ),
      ],
    );
  }
}

class _DashTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DashTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
