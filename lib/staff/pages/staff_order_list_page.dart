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
  String _statusFilter = 'ALL';
  // In-memory cache
  final Map<String, List<OrderModel>> _cache = {};
  DateTime? _lastFetch;

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

  bool get _stale =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!) > const Duration(seconds: 30);

  // Cache for fallback dine-in items to avoid duplicate calls
  static final Map<String, List<FoodOrder>> _dineInItemsCache = {};

  Future<OrderModel> _enhanceOrderWithFallback(OrderModel order) async {
    // Only enhance dine-in orders with empty foodList
    if (!_isDineIn(order) || order.foodList.isNotEmpty) {
      return order;
    }

    // Check cache first
    if (_dineInItemsCache.containsKey(order.id)) {
      final cachedItems = _dineInItemsCache[order.id]!;
      debugPrint(
        '[FALLBACK CACHE] Using cached items for order ${order.orderNumber}',
      );
      return order.copyWith(foodList: cachedItems);
    }

    // Fetch from dine-in endpoint
    try {
      final api = context.read<ApiService>();
      final res = await api.client.get(
        Uri.parse('${api.baseUrl}/api/dinein/orders/${order.id}'),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          final data = jsonDecode(body);
          if (data is Map<String, dynamic> && data.containsKey('orderItems')) {
            final orderItems = data['orderItems'] as List<dynamic>? ?? [];
            debugPrint(
              '[FALLBACK] Found ${orderItems.length} items for order ${order.orderNumber}',
            );

            // Convert to FoodOrder list
            final foodOrders = FoodOrder.fromDineInItems(orderItems);

            // Cache the items
            _dineInItemsCache[order.id] = foodOrders;

            // Return enhanced order with fallback items
            return order.copyWith(foodList: foodOrders);
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[FALLBACK ERROR] Failed to fetch dine-in items for ${order.orderNumber}: $e',
      );
    }

    return order;
  }

  Future<List<OrderModel>> _fetchDineInOrders() async {
    final api = context.read<ApiService>();
    try {
      final res = await api.client.get(Uri.parse('${api.baseUrl}/api/orders'));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          debugPrint('[STAFF DINE-IN ORDERS] $body');
          final data = jsonDecode(body);
          if (data is List) {
            final entities = OrderEntity.listFromJson(data);
            final allOrders = entities.map(OrderModel.fromEntity).toList();

            // Filter for dine-in orders only
            final dineInOrders = allOrders
                .where((order) => _isDineIn(order))
                .toList();

            // Enhance with fallback items for empty foodList
            final enhancedOrders = <OrderModel>[];
            for (final order in dineInOrders) {
              if (order.foodList.isEmpty) {
                final enhanced = await _enhanceOrderWithFallback(order);
                enhancedOrders.add(enhanced);
              } else {
                enhancedOrders.add(order);
              }
            }
            return enhancedOrders;
          }
        }
      } else {
        debugPrint(
          '[STAFF DINE-IN ORDERS] HTTP ${res.statusCode}: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint('[STAFF DINE-IN ORDERS FETCH ERROR] $e');
    }
    return [];
  }

  Future<List<OrderModel>> _fetchTakeAwayOrders() async {
    final api = context.read<ApiService>();
    try {
      final res = await api.client.get(Uri.parse('${api.baseUrl}/api/orders'));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          debugPrint('[STAFF TAKE-AWAY ORDERS] $body');
          final data = jsonDecode(body);
          if (data is List) {
            final entities = OrderEntity.listFromJson(data);
            final allOrders = entities.map(OrderModel.fromEntity).toList();

            // Filter for take-away orders only (not delivery, not dine-in)
            final takeAwayOrders = allOrders
                .where((order) => _isTakeAway(order) && !_isDelivery(order))
                .toList();
            debugPrint(
              '[STAFF TAKE-AWAY ORDERS] Filtered ${takeAwayOrders.length} take-away orders from ${allOrders.length} total',
            );
            return takeAwayOrders;
          }
        }
      } else {
        debugPrint(
          '[STAFF TAKE-AWAY ORDERS] HTTP ${res.statusCode}: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint('[STAFF TAKE-AWAY ORDERS FETCH ERROR] $e');
    }
    return [];
  }

  Future<List<OrderModel>> _fetchDeliveryOrders() async {
    final api = context.read<ApiService>();
    try {
      // Use the general orders endpoint with delivery status filter for now
      final res = await api.client.get(Uri.parse('${api.baseUrl}/api/orders'));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          debugPrint('[STAFF DELIVERY ORDERS RAW] $body');
          final data = jsonDecode(body);
          if (data is List) {
            final entities = OrderEntity.listFromJson(data);
            final allOrders = entities.map(OrderModel.fromEntity).toList();

            // Filter delivery orders using heuristics
            final deliveryOrders = allOrders.where(_isDelivery).toList();
            debugPrint(
              '[STAFF DELIVERY ORDERS] Filtered ${deliveryOrders.length} delivery orders from ${allOrders.length} total',
            );
            return deliveryOrders;
          }
        }
      } else {
        debugPrint(
          '[STAFF DELIVERY ORDERS] HTTP ${res.statusCode}: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint('[STAFF DELIVERY ORDERS FETCH ERROR] $e');
    }
    return [];
  }

  Future<List<OrderModel>> _fetchByType(String type) async {
    if (!_stale && _cache.containsKey(type)) return _cache[type]!;

    List<OrderModel> orders;
    switch (type) {
      case 'DINE_IN':
        orders = await _fetchDineInOrders();
        break;
      case 'TAKE_AWAY':
        orders = await _fetchTakeAwayOrders();
        break;
      case 'DELIVERY':
        orders = await _fetchDeliveryOrders();
        break;
      default:
        orders = [];
    }

    _cache[type] = orders;
    _lastFetch = DateTime.now();

    debugPrint('[STAFF ORDERS] Fetched ${orders.length} orders for type $type');
    return orders;
  }

  bool _isDelivery(OrderModel o) {
    final hasAddr =
        o.deliveryAddress != null && o.deliveryAddress!.trim().isNotEmpty;
    final hasDeliveryStatus =
        o.deliveryStatus != null && o.deliveryStatus!.trim().isNotEmpty;
    final hasRecipient =
        (o.recipientName != null && o.recipientName!.trim().isNotEmpty) ||
        (o.recipientPhone != null && o.recipientPhone!.trim().isNotEmpty);
    final status = o.status.toUpperCase();
    final shippingKeyword =
        status.contains('SHIP') ||
        status.contains('DELIVER') ||
        status.contains('COURIER');

    // Check for delivery prefix in order number
    final number = o.orderNumber.toUpperCase();
    final hasDeliveryPrefix =
        number.startsWith('DEL') || number.startsWith('DL');

    // Treat as delivery if any delivery markers are present, excluding explicit take-away/dine-in prefixes
    final isDelivery =
        hasAddr ||
        hasDeliveryStatus ||
        hasRecipient ||
        shippingKeyword ||
        hasDeliveryPrefix;
    final isExplicitlyNotDelivery =
        number.startsWith('TA') ||
        number.startsWith('DIN') ||
        number.startsWith('DI');

    return isDelivery && !isExplicitlyNotDelivery;
  }

  bool _isTakeAway(OrderModel o) {
    final s = o.status.toUpperCase();
    final number = o.orderNumber.toUpperCase();
    if (_isDelivery(o)) return false;
    // Prefer explicit prefix or status keywords for take-away recognition
    if (number.startsWith('TA')) return true;
    return s.contains('TAKE') || s.contains('AWAY');
  }

  bool _isDineIn(OrderModel o) {
    if (_isDelivery(o) || _isTakeAway(o)) return false;
    // Require an internal dine-in style order number prefix if available
    final number = o.orderNumber.toUpperCase();
    final looksLikeDineInNumber =
        number.startsWith('DIN') || number.startsWith('DI');
    final noAddr =
        o.deliveryAddress == null || o.deliveryAddress!.trim().isEmpty;
    final noRecipient =
        (o.recipientName == null || o.recipientName!.trim().isEmpty) &&
        (o.recipientPhone == null || o.recipientPhone!.trim().isEmpty);

    // STRICT: Only accept orders with explicit DIN prefix OR very clear dine-in markers
    if (looksLikeDineInNumber && noAddr) return true;

    // Only fallback to no-address check if status suggests in-house dining
    final status = o.status.toUpperCase();
    final hasDineInStatus = status.contains('DINE') || status.contains('TABLE');

    return noAddr && noRecipient && hasDineInStatus;
  }

  List<String> _getStatusOptions(String orderType) {
    switch (orderType) {
      case 'DINE_IN':
        return [
          'ALL',
          'PENDING',
          'CONFIRMED',
          'PREPARING',
          'READY',
          'COMPLETED',
          'CANCELLED',
        ];
      case 'TAKE_AWAY':
        return [
          'ALL',
          'PENDING',
          'PAID',
          'PREPARING',
          'READY',
          'COMPLETED',
          'CANCELLED',
        ];
      case 'DELIVERY':
        return [
          'ALL',
          'PREPARING',
          'WAITING_FOR_SHIPPER',
          'DELIVERING',
          'COMPLETED',
        ];
      default:
        return ['ALL'];
    }
  }

  List<String> _getCurrentStatusOptions() {
    // Get status options for currently active tab
    final currentTab = _tabController.index;
    switch (currentTab) {
      case 0:
        return _getStatusOptions('DINE_IN');
      case 1:
        return _getStatusOptions('TAKE_AWAY');
      case 2:
        return _getStatusOptions('DELIVERY');
      default:
        return ['ALL'];
    }
  }

  List<OrderModel> _filterOrdersByStatus(List<OrderModel> orders) {
    if (_statusFilter == 'ALL') return orders;
    return orders
        .where((order) => order.status.toUpperCase() == _statusFilter)
        .toList();
  }

  // (Removed unused enhanced function; strengthened logic inside _isDelivery directly)

  Future<void> _goDetail(String id) async {
    // Determine order type by checking which cache contains the order
    String route = '/staff/orders/detail';

    // Check each cache to find which type the order belongs to
    if (_cache.containsKey('DINE_IN')) {
      final dineInOrders = _cache['DINE_IN']!;
      if (dineInOrders.any((e) => e.id == id)) {
        route = '/staff/orders/dinein/detail';
      }
    }

    if (_cache.containsKey('TAKE_AWAY')) {
      final takeAwayOrders = _cache['TAKE_AWAY']!;
      if (takeAwayOrders.any((e) => e.id == id)) {
        route = '/staff/orders/takeaway/detail';
      }
    }

    if (_cache.containsKey('DELIVERY')) {
      final deliveryOrders = _cache['DELIVERY']!;
      if (deliveryOrders.any((e) => e.id == id)) {
        route = '/staff/orders/delivery/detail';
      }
    }

    await Navigator.pushNamed(context, route, arguments: id);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload & Reclassify',
            onPressed: _forceReload,
          ),
        ],
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
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    hintText: 'Search orders...',
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Status: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        items: _getCurrentStatusOptions().map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() {
                          _statusFilter = value!;
                          _cache
                              .clear(); // Clear cache to refresh with new filter
                        }),
                      ),
                    ),
                  ],
                ),
              ],
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
        // Apply status filter first
        final filteredByStatus = _filterOrdersByStatus(data);
        // Then apply search filter
        final list = filteredByStatus.where((order) {
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
          onRefresh: () async => _forceReload(),
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
                        'Total: \$${(order.totalPrice / 25000).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (order.foodList.isEmpty)
                        Text(
                          'Server returned empty foodList',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade400,
                            fontStyle: FontStyle.italic,
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

  void _forceReload() {
    _cache.clear();
    _dineInItemsCache.clear();
    _lastFetch = null;
    setState(() {});
    debugPrint(
      '[STAFF ORDERS] Force reload triggered -> cache cleared, dine-in fallback cache cleared',
    );
  }
}
