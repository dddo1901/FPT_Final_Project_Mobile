import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_model.dart';
import '../services/food_service.dart';
import '../../styles/app_theme.dart';

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
        return AppTheme.success;
      case 'UNAVAILABLE':
        return AppTheme.danger;
      default:
        return AppTheme.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Foods',
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
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search foods by name...',
                  hintStyle: TextStyle(color: AppTheme.textLight),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snap.error}',
                            style: TextStyle(color: AppTheme.danger),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final list = snap.data ?? const <FoodModel>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No foods found',
                            style: TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final f = list[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
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
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.cardHeaderGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                            ),
                            title: Text(
                              f.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  f.priceText,
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      f.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: _statusColor(f.status),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        f.status,
                                        style: TextStyle(
                                          color: _statusColor(f.status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: AppTheme.textLight,
                              size: 16,
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
      ),
    );
  }
}
