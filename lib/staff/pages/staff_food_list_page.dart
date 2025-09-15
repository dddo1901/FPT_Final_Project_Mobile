import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/models/food_model.dart';
import '../../admin/services/food_service.dart';

class StaffFoodListPage extends StatefulWidget {
  const StaffFoodListPage({super.key});

  @override
  State<StaffFoodListPage> createState() => _StaffFoodListPageState();
}

class _StaffFoodListPageState extends State<StaffFoodListPage> {
  late Future<List<FoodModel>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = context.read<FoodService>().filterFoods(name: _search);
  }

  Future<void> _fetch() async {
    try {
      final data = await context.read<FoodService>().filterFoods(name: _search);
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
      '/admin/foods/detail', // reuse admin detail page
      arguments: id,
    );
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
        backgroundColor: Colors.blue.shade50,
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
                hintText: 'Search foods by name...',
              ),
              onChanged: (v) {
                _search = v.trim();
                _reload();
              },
            ),
          ),
          // Food list
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
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = list[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
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
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.grey.shade500,
                                      size: 32,
                                    ),
                                  ),
                          ),
                          title: Text(
                            f.name,
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
                                f.priceText,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              if (f.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  f.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: f.status == 'AVAILABLE'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _statusColor(f.status),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: _statusColor(f.status),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  f.status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(f.status),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => _goDetail(f.id),
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
