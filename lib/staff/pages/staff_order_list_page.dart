import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../admin/models/order_model.dart';
import '../../admin/entities/order_entity.dart';
import '../../auths/api_service.dart';
import '../../styles/app_theme.dart';

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
    if (order.foodList.isNotEmpty) {
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
          if (data is Map<String, dynamic> &&
              (data.containsKey('foodList') ||
                  data.containsKey('orderItems'))) {
            // Try both foodList and orderItems since dine-in has different structure
            final itemsList =
                (data['foodList'] as List<dynamic>?) ??
                (data['orderItems'] as List<dynamic>?) ??
                [];
            debugPrint(
              '[FALLBACK] Found ${itemsList.length} items for order ${order.orderNumber}',
            );

            // Convert to FoodOrder list
            final foodOrders = FoodOrder.fromDineInItems(itemsList);

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
      final res = await api.client.get(
        Uri.parse('${api.baseUrl}/api/dinein/orders/all'),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          debugPrint(
            '[STAFF DINE-IN ORDERS] Raw response length: ${body.length}',
          );
          final data = jsonDecode(body);
          debugPrint(
            '[STAFF DINE-IN ORDERS] Parsed data type: ${data.runtimeType}',
          );
          if (data is List) {
            debugPrint('[STAFF DINE-IN ORDERS] List length: ${data.length}');
            final entities = OrderEntity.listFromJson(data);
            final allOrders = entities.map(OrderModel.fromEntity).toList();

            // Filter for dine-in orders by orderNumber prefix "DIN"
            final dineInOrders = allOrders.where((order) {
              return order.orderNumber.toUpperCase().startsWith('DIN');
            }).toList();

            // Sort by createdAt descending (newest first)
            dineInOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            debugPrint(
              '[STAFF DINE-IN ORDERS] Filtered ${dineInOrders.length} dine-in orders from ${allOrders.length} total',
            );

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
    } catch (e, stackTrace) {
      debugPrint('[STAFF DINE-IN ORDERS FETCH ERROR] $e');
      debugPrint('[STAFF DINE-IN ORDERS STACK] $stackTrace');
    }
    return [];
  }

  Future<List<OrderModel>> _fetchTakeAwayOrders() async {
    final api = context.read<ApiService>();
    try {
      final res = await api.client.get(
        Uri.parse('${api.baseUrl}/api/orders'), // Lấy tất cả orders
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          debugPrint(
            '[STAFF TAKE-AWAY ORDERS] Raw response length: ${body.length}',
          );
          final data = jsonDecode(body);
          debugPrint(
            '[STAFF TAKE-AWAY ORDERS] Parsed data type: ${data.runtimeType}',
          );
          if (data is List) {
            debugPrint('[STAFF TAKE-AWAY ORDERS] List length: ${data.length}');
            final entities = OrderEntity.listFromJson(data);
            final allOrders = entities.map(OrderModel.fromEntity).toList();

            // Filter for take-away orders by orderNumber prefix "TA"
            final takeAwayOrders = allOrders.where((order) {
              final orderNum = order.orderNumber.toUpperCase();
              return orderNum.startsWith('TA');
            }).toList();

            // Sort by createdAt descending (newest first)
            takeAwayOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
    } catch (e, stackTrace) {
      debugPrint('[STAFF TAKE-AWAY ORDERS FETCH ERROR] $e');
      debugPrint('[STAFF TAKE-AWAY ORDERS STACK] $stackTrace');
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
          debugPrint(
            '[STAFF DELIVERY ORDERS] Raw response length: ${body.length}',
          );
          final data = jsonDecode(body);
          debugPrint(
            '[STAFF DELIVERY ORDERS] Parsed data type: ${data.runtimeType}',
          );
          if (data is List) {
            debugPrint('[STAFF DELIVERY ORDERS] List length: ${data.length}');
            final entities = OrderEntity.listFromJson(data);
            final allOrders = entities.map(OrderModel.fromEntity).toList();

            // Filter delivery orders by orderNumber prefix "DEL" or deliveryAddress presence
            final deliveryOrders = allOrders.where((order) {
              final orderNum = order.orderNumber.toUpperCase();
              final hasDeliveryAddr =
                  order.deliveryAddress != null &&
                  order.deliveryAddress!.trim().isNotEmpty;

              return orderNum.startsWith('DEL') ||
                  orderNum.startsWith('DELIVERY') ||
                  hasDeliveryAddr;
            }).toList();

            // Sort by createdAt descending (newest first)
            deliveryOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
    } catch (e, stackTrace) {
      debugPrint('[STAFF DELIVERY ORDERS FETCH ERROR] $e');
      debugPrint('[STAFF DELIVERY ORDERS STACK] $stackTrace');
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
        return AppTheme.warning;
      case 'CONFIRMED':
        return AppTheme.info;
      case 'PREPARING':
        return AppTheme.primary;
      case 'READY':
        return AppTheme.success;
      case 'COMPLETED':
      case 'DELIVERED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      default:
        return AppTheme.textMedium;
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Orders (Staff)',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload & Reclassify',
            onPressed: _forceReload,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Dine-In'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Take-Away'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Delivery'),
          ],
        ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.primary,
                      ),
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
                      hintText: 'Search orders...',
                      hintStyle: const TextStyle(color: AppTheme.textMedium),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            isExpanded: true,
                            underline: const SizedBox(),
                            style: const TextStyle(color: AppTheme.textDark),
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
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders found',
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
          onRefresh: () async => _forceReload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final order = list[i];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.softShadow,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _goDetail(order.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardHeaderGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #${order.orderNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(order.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  order.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor(
                                    order.status,
                                  ).withOpacity(0.3),
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: AppTheme.divider, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: AppTheme.success,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (order.foodList.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Empty food list',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
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
