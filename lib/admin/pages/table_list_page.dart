import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../entities/table_entity.dart';
import '../services/table_service.dart';

class TableListPage extends StatefulWidget {
  const TableListPage({super.key});

  @override
  State<TableListPage> createState() => _TableListPageState();
}

class _TableListPageState extends State<TableListPage> {
  late Future<List<TableEntity>> _future; // nguồn dữ liệu cho UI
  String _search = '';

  @override
  void initState() {
    super.initState();
    // KHỞI TẠO ban đầu: ok dùng context.read trong initState
    _future = context.read<TableService>().getTables();
  }

  // ⛳️ HÀM FETCH CHUẨN — async ngoài setState
  Future<void> _fetch() async {
    try {
      final data = await context.read<TableService>().getTables();
      if (!mounted) return;
      // setState chỉ gán future “đã có kết quả” => không return Future trong callback
      setState(() {
        _future = Future.value(data);
      });
    } catch (e) {
      // vẫn setState để FutureBuilder hiển thị lỗi
      if (!mounted) return;
      setState(() {
        _future = Future.error(e);
      });
    }
  }

  // 🔁 Reload được gọi từ AppBar hoặc sau khi pop(true)
  void _reload() {
    // KHÔNG async bên trong setState
    // gọi _fetch() (async) để cập nhật _future
    _fetch();
  }

  // Pull-to-refresh cần Future<void>
  Future<void> _onRefresh() => _fetch();

  // Điều hướng
  Future<void> _goCreate() async {
    final ok = await Navigator.pushNamed(context, '/admin/tables/create');
    if (!mounted) return;
    if (ok == true) _reload();
  }

  Future<void> _goDetail(String id) async {
    final ok = await Navigator.pushNamed(
      context,
      '/admin/tables/detail',
      arguments: id,
    );
    if (!mounted) return;
    if (ok == true) _reload();
  }

  Future<void> _goEdit(String id) async {
    final ok = await Navigator.pushNamed(
      context,
      '/admin/tables/edit',
      arguments: id,
    );
    if (!mounted) return;
    if (ok == true) _reload();
  }

  // Hiển thị text
  String _title(TableEntity t) => 'Table #${t.number ?? t.id}';
  String _capacityText(TableEntity t) => 'Capacity: ${t.capacity ?? "—"}';
  String _statusOf(TableEntity t) => (t.status ?? 'UNKNOWN').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          FilledButton.tonalIcon(
            onPressed: _goCreate,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
      body: Column(
        children: [
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
                  onRefresh:
                      _onRefresh, // ✅ trả Future<void>, không setState async bên trong
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final t = list[i];
                      return ListTile(
                        title: Text(
                          _title(t),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_capacityText(t)),
                        trailing: _StatusChip(status: _statusOf(t)),
                        onTap: () => _goDetail(t.id), // xem chi tiết
                        onLongPress: () => _goEdit(t.id), // edit nhanh
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _bg() {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green.withOpacity(0.15);
      case 'OCCUPIED':
        return Colors.orange.withOpacity(0.15);
      case 'RESERVED':
        return Colors.blue.withOpacity(0.15);
      case 'CLEANING':
        return Colors.purple.withOpacity(0.15);
      case 'INACTIVE':
        return Colors.grey.withOpacity(0.15);
      default:
        return Colors.black12;
    }
  }

  Color _fg() {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green.shade700;
      case 'OCCUPIED':
        return Colors.orange.shade800;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(fontWeight: FontWeight.w600, color: _fg()),
      ),
    );
  }
}
