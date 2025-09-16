import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../entities/table_entity.dart';
import '../services/table_service.dart';
import '../../styles/app_theme.dart';

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

  // Điều hướng - chỉ giữ detail
  Future<void> _goDetail(String id) async {
    await Navigator.pushNamed(context, '/admin/tables/detail', arguments: id);
    // Không cần reload sau khi xem detail vì không có thay đổi
  }

  // Hiển thị text
  String _title(TableEntity t) => 'Table #${t.number ?? t.id}';
  String _capacityText(TableEntity t) => 'Capacity: ${t.capacity ?? "—"}';
  String _statusOf(TableEntity t) => (t.status ?? 'UNKNOWN').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Tables',
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
                  hintText: 'Search by table number...',
                  hintStyle: TextStyle(color: AppTheme.textLight),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
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

                  final data = snap.data ?? const <TableEntity>[];
                  final list = data.where((t) {
                    if (_search.isEmpty) return true;
                    final key = (t.number ?? t.id).toString();
                    return key.contains(_search);
                  }).toList();

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant_outlined,
                            size: 64,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tables found',
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
                        final t = list[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardHeaderGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.table_restaurant,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              _title(t),
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
                                  _capacityText(t),
                                  style: TextStyle(color: AppTheme.textMedium),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(t).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _statusOf(t),
                                    style: TextStyle(
                                      color: _getStatusColor(t),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: AppTheme.textLight,
                              size: 16,
                            ),
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
      ),
    );
  }

  Color _getStatusColor(TableEntity t) {
    final status = _statusOf(t);
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.success;
      case 'OCCUPIED':
        return AppTheme.warning;
      case 'RESERVED':
        return AppTheme.info;
      case 'MAINTENANCE':
        return AppTheme.danger;
      default:
        return AppTheme.textMedium;
    }
  }
}
