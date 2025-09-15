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

  // Điều hướng - chỉ giữ detail
  Future<void> _goDetail(String id) async {
    await Navigator.pushNamed(context, '/admin/foods/detail', arguments: id);
    // Không reload vì chỉ xem detail
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
                        trailing: Container(
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
                        onTap: () => _goDetail(f.id), // chỉ xem detail
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
