import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/entities/table_entity.dart';
import '../../admin/services/table_service.dart';
import '../../styles/app_theme.dart';

class StaffTableListPage extends StatefulWidget {
  const StaffTableListPage({super.key});

  @override
  State<StaffTableListPage> createState() => _StaffTableListPageState();
}

class _StaffTableListPageState extends State<StaffTableListPage> {
  late Future<List<TableEntity>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = context.read<TableService>().getTables();
  }

  Future<void> _fetch() async {
    try {
      final data = await context.read<TableService>().getTables();
      if (!mounted) return;
      setState(() {
        _future = Future.value(data);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _future = Future.error(e);
      });
    }
  }

  void _reload() {
    _fetch();
  }

  Future<void> _onRefresh() => _fetch();

  // Staff can only view details
  Future<void> _goDetail(String id) async {
    await Navigator.pushNamed(
      context,
      '/admin/tables/detail', // reuse admin detail page
      arguments: id,
    );
  }

  String _title(TableEntity t) => 'Table #${t.number ?? t.id}';
  String _capacityText(TableEntity t) => 'Capacity: ${t.capacity ?? "—"}';
  String _statusOf(TableEntity t) => (t.status ?? 'UNKNOWN').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Tables (Staff)',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.ultraLightBlue, AppTheme.surface],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primary.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  hintText: 'Search by table number...',
                  hintStyle: const TextStyle(color: AppTheme.textMedium),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            // Table list
            Expanded(
              child: FutureBuilder<List<TableEntity>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.danger.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.danger,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snap.error}',
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snap.data ?? const <TableEntity>[];
                  final list = data.where((t) {
                    if (_search.isEmpty) return true;
                    final key = (t.number ?? t.id).toString();
                    return key.contains(_search);
                  }).toList();

                  if (list.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_restaurant_outlined,
                              size: 64,
                              color: AppTheme.textMedium,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No tables found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final t = list[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _goDetail(t.id),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.cardHeaderGradient,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.table_restaurant,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _title(t),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _capacityText(t),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _StaffStatusChip(status: _statusOf(t)),
                                    ],
                                  ),
                                  if (t.location != null) ...[
                                    const SizedBox(height: 12),
                                    Divider(color: AppTheme.divider, height: 1),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: AppTheme.warning,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Location: ${t.location}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffStatusChip extends StatelessWidget {
  final String status;
  const _StaffStatusChip({required this.status});

  Color _bg() {
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.success.withOpacity(0.1);
      case 'OCCUPIED':
        return AppTheme.danger.withOpacity(0.1);
      case 'RESERVED':
        return AppTheme.info.withOpacity(0.1);
      case 'CLEANING':
        return AppTheme.warning.withOpacity(0.1);
      case 'INACTIVE':
        return AppTheme.textMedium.withOpacity(0.1);
      default:
        return AppTheme.textMedium.withOpacity(0.1);
    }
  }

  Color _fg() {
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.success;
      case 'OCCUPIED':
        return AppTheme.danger;
      case 'RESERVED':
        return AppTheme.info;
      case 'CLEANING':
        return AppTheme.warning;
      case 'INACTIVE':
        return AppTheme.textMedium;
      default:
        return AppTheme.textMedium;
    }
  }

  IconData _icon() {
    switch (status) {
      case 'AVAILABLE':
        return Icons.check_circle;
      case 'OCCUPIED':
        return Icons.people;
      case 'RESERVED':
        return Icons.bookmark;
      case 'CLEANING':
        return Icons.cleaning_services;
      case 'INACTIVE':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fg(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 14, color: _fg()),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _fg(),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
