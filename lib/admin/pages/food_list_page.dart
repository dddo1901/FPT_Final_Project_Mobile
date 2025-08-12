import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_model.dart';
import '../services/food_service.dart';

class FoodListPage extends StatefulWidget {
  const FoodListPage({super.key});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  late Future<List<FoodModel>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Khởi tạo future ban đầu
    _future = context.read<FoodService>().filterFoods(name: _search);
  }

  // ✅ Giống TableList: fetch async bên ngoài setState
  Future<void> _fetch() async {
    try {
      final data = await context.read<FoodService>().filterFoods(name: _search);
      if (!mounted) return;
      setState(() {
        _future = Future.value(data); // gán future đã có kết quả
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _future = Future.error(e);
      });
    }
  }

  // 🔁 Reload tiêu chuẩn
  void _reload() {
    _fetch(); // KHÔNG async trong setState
  }

  // ⤵️ Pull-to-refresh
  Future<void> _onRefresh() => _fetch();

  // Điều hướng
  Future<void> _goCreate() async {
    final ok = await Navigator.pushNamed(context, '/admin/foods/create');
    if (!mounted) return;
    if (ok == true) _reload();
  }

  Future<void> _goDetail(String id) async {
    final ok = await Navigator.pushNamed(
      context,
      '/admin/foods/detail',
      arguments: id,
    );
    if (!mounted) return;
    if (ok == true) _reload();
  }

  Future<void> _goEdit(String id) async {
    final ok = await Navigator.pushNamed(
      context,
      '/admin/foods/edit',
      arguments: id,
    );
    if (!mounted) return;
    if (ok == true) _reload();
  }

  Future<void> _setStatus(FoodModel f, String newStatus) async {
    try {
      await context.read<FoodService>().updateStatus(f.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Set "${f.name}" → $newStatus')));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Change status failed: $e')));
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'AVAILABLE':
        return Colors.green.shade700;
      case 'UNAVAILABLE':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foods'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          FilledButton.tonalIcon(
            onPressed: _goCreate,
            icon: const Icon(Icons.add),
            label: const Text('Add Food'),
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
                hintText: 'Search foods by name...',
              ),
              onChanged: (v) {
                _search = v.trim();
                _reload(); // gọi fetch; không setState async
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FoodModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final list = snap.data ?? const <FoodModel>[];
                if (list.isEmpty) return const Center(child: Text('No foods'));

                return RefreshIndicator(
                  onRefresh: _onRefresh, // dùng _fetch() trả Future<void>
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = list[i];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: f.imageUrl != null
                              ? Image.network(
                                  f.imageUrl!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'No\nImg',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                        title: Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(f.priceText),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _setStatus(f, value),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'AVAILABLE',
                              child: Text('Set AVAILABLE'),
                            ),
                            PopupMenuItem(
                              value: 'UNAVAILABLE',
                              child: Text('Set UNAVAILABLE'),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _statusColor(f.status),
                                ),
                                const SizedBox(width: 6),
                                Text(f.status),
                              ],
                            ),
                          ),
                        ),
                        onTap: () => _goDetail(f.id),
                        onLongPress: () => _goEdit(f.id),
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
