import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/models/food_model.dart';
import '../../admin/services/food_service.dart';
import '../../styles/app_theme.dart';

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
          'Foods (Staff)',
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
                  hintText: 'Search foods by name...',
                  hintStyle: const TextStyle(color: AppTheme.textMedium),
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

                  final list = snap.data ?? const <FoodModel>[];
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
                              Icons.restaurant_outlined,
                              size: 64,
                              color: AppTheme.textMedium,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No foods found',
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
                        final f = list[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _goDetail(f.id),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: f.imageUrl != null
                                        ? Image.network(
                                            f.imageUrl!,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppTheme.cardHeaderGradient,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.restaurant,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.attach_money,
                                              color: AppTheme.success,
                                              size: 16,
                                            ),
                                            Text(
                                              f.priceText,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (f.description != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            f.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppTheme.textMedium,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        f.status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _statusColor(
                                          f.status,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          f.status == 'AVAILABLE'
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 14,
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
