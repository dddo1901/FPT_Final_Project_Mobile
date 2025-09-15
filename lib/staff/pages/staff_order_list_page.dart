import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../admin/models/order_model.dart';
import '../../admin/entities/order_entity.dart';
import '../../auths/api_service.dart';

class StaffOrderListPage extends StatefulWidget {
  const StaffOrderListPage({super.key});

  @override
  State<StaffOrderListPage> createState() => _StaffOrderListPageState();
}

class _StaffOrderListPageState extends State<StaffOrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<OrderModel>> _fetchByType(String type) async {
    final api = context.read<ApiService>();
    List<OrderEntity> entities = [];
    String endpoint;
    switch (type) {
      case 'DINE_IN':
        endpoint = '/api/admin/orders/dine-in';
        break;
      case 'TAKE_AWAY':
        endpoint = '/api/admin/orders/take-away';
        break;
      case 'DELIVERY':
        endpoint = '/api/orders/filter?type=DELIVERY';
        break;
      default:
        endpoint = '/api/admin/orders';
    }
    try {
      final res = await api.client.get(Uri.parse('${api.baseUrl}$endpoint'));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          final data = jsonDecode(body);
          if (data is List) {
            entities = OrderEntity.listFromJson(data);
          }
        }
      }
    } catch (e) {
      debugPrint('Fetch $type error: $e');
    }
    return entities.map(OrderModel.fromEntity).toList();
  }

  Future<void> _goDetail(String id) async {
    await Navigator.pushNamed(context, '/staff/orders/detail', arguments: id);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'CONFIRMED':
        return Colors.blue.shade700;
      case 'PREPARING':
        return Colors.purple.shade700;
      case 'READY':
        return Colors.green.shade700;
      case 'COMPLETED':
        return Colors.grey.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.schedule;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'PREPARING':
        return Icons.restaurant;
      case 'READY':
        return Icons.done_all;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders (Staff)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Dine-In'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Take-Away'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Delivery'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Search orders...',
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('DINE_IN'),
                _buildOrderList('TAKE_AWAY'),
                _buildOrderList('DELIVERY'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String type) {
    return FutureBuilder<List<OrderModel>>(
      future: _fetchByType(type),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final data = snap.data ?? const <OrderModel>[];
        final list = data.where((order) {
          if (_search.isEmpty) return true;
          final s = _search.toLowerCase();
          return order.orderNumber.toLowerCase().contains(s) ||
              order.status.toLowerCase().contains(s) ||
              order.id.toLowerCase().contains(s);
        }).toList();
        if (list.isEmpty) {
          return const Center(child: Text('No orders'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final order = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  title: Text(
                    'Order #${order.orderNumber}',
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
                        'Created: ${_formatDate(order.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: ${order.totalPrice.toStringAsFixed(2)}đ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _statusColor(order.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(order.status),
                          size: 14,
                          color: _statusColor(order.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _statusColor(order.status),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _goDetail(order.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
