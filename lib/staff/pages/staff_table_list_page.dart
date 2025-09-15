import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/entities/table_entity.dart';
import '../../admin/services/table_service.dart';

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

  // Staff chỉ có thể xem detail
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
      appBar: AppBar(
        title: const Text('Tables'),
        backgroundColor: Colors.orange.shade50,
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Search by table number...',
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final data = snap.data ?? const <TableEntity>[];
                final list = data.where((t) {
                  if (_search.isEmpty) return true;
                  final key = (t.number ?? t.id).toString();
                  return key.contains(_search);
                }).toList();

                if (list.isEmpty) return const Center(child: Text('No tables'));

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final t = list[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(
                              Icons.table_restaurant,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          title: Text(
                            _title(t),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _capacityText(t),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (t.location != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Location: ${t.location}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: _StaffStatusChip(status: _statusOf(t)),
                          onTap: () => _goDetail(t.id),
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
    );
  }
}

class _StaffStatusChip extends StatelessWidget {
  final String status;
  const _StaffStatusChip({required this.status});

  Color _bg() {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green.withValues(alpha: 0.1);
      case 'OCCUPIED':
        return Colors.red.withValues(alpha: 0.1);
      case 'RESERVED':
        return Colors.blue.withValues(alpha: 0.1);
      case 'CLEANING':
        return Colors.purple.withValues(alpha: 0.1);
      case 'INACTIVE':
        return Colors.grey.withValues(alpha: 0.1);
      default:
        return Colors.black12;
    }
  }

  Color _fg() {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green.shade700;
      case 'OCCUPIED':
        return Colors.red.shade700;
      case 'RESERVED':
        return Colors.blue.shade700;
      case 'CLEANING':
        return Colors.purple.shade700;
      case 'INACTIVE':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade800;
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
