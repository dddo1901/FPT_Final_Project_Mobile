import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/order_model.dart';
import '../entities/order_entity.dart';
import '../../auths/api_service.dart';
import '../../styles/app_theme.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<OrderModel> _future;
  // Simple in-memory cache for fallback dine-in items
  static final Map<String, List<FoodOrder>> _dineInItemsCache = {};

  @override
  void initState() {
    super.initState();
    _future = _getOrderById(widget.orderId);
  }

  Future<OrderModel> _getOrderById(String id) async {
    final apiService = context.read<ApiService>();
    final response = await apiService.client.get(
      Uri.parse('${apiService.baseUrl}/api/orders/$id'),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.bodyBytes.isNotEmpty
          ? utf8.decode(response.bodyBytes)
          : '';
      final entity = OrderEntity.fromJson(jsonDecode(body));
      var model = OrderModel.fromEntity(entity);
      // Fallback: likely a dine-in order whose items live in /api/dinein/orders/{id}
      if (model.foodList.isEmpty && _looksLikeDineIn(model)) {
        final fallbackItems = await _fetchDineInItems(id, apiService);
        if (fallbackItems.isNotEmpty) {
          final newTotal = fallbackItems.fold<double>(
            0,
            (s, f) => s + f.price * f.quantity,
          );
          model = model.copyWith(foodList: fallbackItems, totalPrice: newTotal);
        }
      }
      return model;
    }
    throw Exception(
      'GET order by id -> ${response.statusCode}: ${response.body}',
    );
  }

  bool _looksLikeDineIn(OrderModel o) {
    // Heuristic: no delivery address AND orderNumber not starting with TA (take-away prefix)
    final addrEmpty =
        (o.deliveryAddress == null || o.deliveryAddress!.trim().isEmpty);
    final notTakeAway = !o.orderNumber.toUpperCase().startsWith('TA');
    return addrEmpty && notTakeAway;
  }

  Future<List<FoodOrder>> _fetchDineInItems(String id, ApiService api) async {
    if (_dineInItemsCache.containsKey(id)) return _dineInItemsCache[id]!;
    try {
      final res = await api.client.get(
        Uri.parse('${api.baseUrl}/api/dinein/orders/$id'),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (raw.isEmpty) return const [];
        final j = jsonDecode(raw);
        if (j is Map<String, dynamic> && j['orderItems'] is List) {
          final items = <FoodOrder>[];
          for (final it in (j['orderItems'] as List)) {
            if (it is Map<String, dynamic>) {
              final idStr = it['foodId']?.toString() ?? '';
              final name = it['foodName']?.toString() ?? '';
              final qty = int.tryParse(it['quantity']?.toString() ?? '1') ?? 1;
              final price = _parseDouble(it['foodPrice']);
              items.add(
                FoodOrder(id: idStr, name: name, quantity: qty, price: price),
              );
            }
          }
          _dineInItemsCache[id] = items;
          debugPrint(
            '[DINEIN FALLBACK] Loaded ${items.length} items for order $id',
          );
          return items;
        }
      } else {
        debugPrint('[DINEIN FALLBACK] HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[DINEIN FALLBACK ERROR] $e');
    }
    return const [];
  }

  double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  void _reload() {
    setState(() {
      _future = _getOrderById(widget.orderId);
    });
  }

  String _fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _reload,
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
        child: FutureBuilder<OrderModel>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
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
                    border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
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
            final order = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order.orderNumber}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                order.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(
                                  order.status,
                                ).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Basic Info Cards
                      _InfoCard(
                        'Created',
                        _fmtDate(order.createdAt),
                        Icons.access_time,
                        AppTheme.info,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        'Delivery Status',
                        order.deliveryStatus ?? '—',
                        Icons.local_shipping,
                        AppTheme.warning,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        'Total Amount',
                        _fmtMoney(order.totalPrice),
                        Icons.attach_money,
                        AppTheme.success,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Customer Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.lightBlue,
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                          ),
                        ),
                        title: Text(
                          order.customer?.fullName ?? 'Guest',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        subtitle: Text(
                          order.customer?.email ?? '—',
                          style: const TextStyle(color: AppTheme.textMedium),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Section - Hide for DINE IN orders
                if (!_looksLikeDineIn(order)) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delivery Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DetailRow('Recipient', order.recipientName),
                        _DetailRow('Phone', order.recipientPhone),
                        _DetailRow('Address', order.deliveryAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payment Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.payment,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailRow('Method', order.paymentMethod?.name),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Items Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Order Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (order.foodList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.warning.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Server returned empty foodList',
                                style: TextStyle(
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        ...order.foodList.map(
                          (food) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        'Quantity: ${food.quantity}',
                                        style: const TextStyle(
                                          color: AppTheme.textMedium,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _fmtMoney(food.price * food.quantity),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppTheme.warning;
      case 'CONFIRMED':
        return AppTheme.info;
      case 'PROCESSING':
        return AppTheme.info;
      case 'DELIVERED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      default:
        return AppTheme.textMedium;
    }
  }

  Widget _DetailRow(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value == null || value.trim().isEmpty ? '—' : value,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
