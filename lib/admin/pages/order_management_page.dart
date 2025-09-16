import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/order_model.dart';
import '../entities/order_entity.dart';
import '../../auths/api_service.dart';
import '../../styles/app_theme.dart';
import 'order_detail_page.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            const OrderTypeTab(
              orderType: 'DINE_IN',
              title: 'Dine-In Orders',
              emptyMessage: 'No dine-in orders found',
            ),
            const OrderTypeTab(
              orderType: 'TAKE_AWAY',
              title: 'Take-Away Orders',
              emptyMessage: 'No take-away orders found',
            ),
            const OrderTypeTab(
              orderType: 'DELIVERY',
              title: 'Delivery Orders',
              emptyMessage: 'No delivery orders found',
            ),
          ],
        ),
      ),
    );
  }
}

class OrderTypeTab extends StatefulWidget {
  final String orderType;
  final String title;
  final String emptyMessage;

  const OrderTypeTab({
    super.key,
    required this.orderType,
    required this.title,
    required this.emptyMessage,
  });

  @override
  State<OrderTypeTab> createState() => _OrderTypeTabState();
}

class _OrderTypeTabState extends State<OrderTypeTab> {
  late Future<List<OrderModel>> _future;
  String _search = '';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    setState(() {
      _future = _fetchByType(widget.orderType);
    });
  }

  Future<List<OrderModel>> _fetchByType(String type) async {
    final apiService = context.read<ApiService>();
    List<OrderEntity> entities = [];
    try {
      String endpoint;
      switch (type) {
        case 'DINE_IN':
          endpoint = '/api/admin/orders/dine-in';
          break;
        case 'TAKE_AWAY':
          endpoint = '/api/admin/orders/take-away';
          break;
        case 'DELIVERY':
          endpoint =
              '/api/orders'; // Sử dụng endpoint chung và filter ở frontend
          break;
        default:
          endpoint = '/api/admin/orders';
      }
      final res = await apiService.client.get(
        Uri.parse('${apiService.baseUrl}$endpoint'),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
        if (body.isNotEmpty) {
          debugPrint('[$type ORDERS] Raw response: $body');
          final data = jsonDecode(body);
          debugPrint('[$type ORDERS] Parsed data type: ${data.runtimeType}');
          if (data is List) {
            debugPrint('[$type ORDERS] List length: ${data.length}');
            entities = OrderEntity.listFromJson(data);
          } else {
            debugPrint('[$type ORDERS] Data is not List: $data');
          }
        }
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching $type orders: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    // Convert to models and filter by orderType for DELIVERY
    var orders = entities.map(OrderModel.fromEntity).toList();

    // Filter by orderType if it's DELIVERY
    if (type == 'DELIVERY') {
      orders = orders.where((order) {
        // Ưu tiên filter theo orderType nếu có
        if (order.orderType != null) {
          return order.orderType == 'DELIVERY';
        }
        // Nếu không có orderType, filter theo orderNumber (loại bỏ TA và DIN)
        final orderNum = order.orderNumber.toUpperCase();
        return !orderNum.contains('TA') && !orderNum.contains('DIN');
      }).toList();
    }

    // Sort by createdAt descending (newest first)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    var filtered = orders;

    // Filter by search
    if (_search.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.orderNumber.toLowerCase().contains(
              _search.toLowerCase(),
            ) ||
            (order.customer?.fullName ?? '').toLowerCase().contains(
              _search.toLowerCase(),
            );
      }).toList();
    }

    // Filter by status
    if (_statusFilter != 'ALL') {
      filtered = filtered.where((order) {
        if (widget.orderType == 'DELIVERY') {
          return order.deliveryStatus == _statusFilter;
        } else {
          return order.status == _statusFilter;
        }
      }).toList();
    }

    // Đảm bảo sắp xếp theo thời gian mới nhất sau khi filter
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  List<String> _getStatusOptions() {
    switch (widget.orderType) {
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
        return ['ALL', 'PREPARING', 'WAITING_FOR_SHIPPER', 'DELIVERING'];
      default:
        return ['ALL'];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppTheme.warning;
      case 'CONFIRMED':
      case 'PAID':
        return AppTheme.success;
      case 'PREPARING':
        return AppTheme.info;
      case 'READY':
        return AppTheme.primary;
      case 'COMPLETED':
      case 'DELIVERED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      case 'WAITING_FOR_SHIPPER':
        return AppTheme.warning;
      case 'DELIVERING':
        return AppTheme.info;
      default:
        return AppTheme.textMedium;
    }
  }

  IconData _getOrderIcon(String orderType) {
    switch (orderType) {
      case 'DINE_IN':
        return Icons.restaurant;
      case 'TAKE_AWAY':
        return Icons.shopping_bag;
      case 'DELIVERY':
        return Icons.delivery_dining;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter
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
                  hintText: 'Search orders...',
                  hintStyle: TextStyle(color: AppTheme.textLight),
                  prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _getStatusOptions().map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: TextStyle(color: AppTheme.textDark),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _statusFilter = value!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchOrders,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Orders List
        Expanded(
          child: FutureBuilder<List<OrderModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                );
              }

              if (snapshot.hasError) {
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
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: AppTheme.danger),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final orders = _filterOrders(snapshot.data ?? []);

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _search.isNotEmpty || _statusFilter != 'ALL'
                            ? 'No orders match your filters'
                            : widget.emptyMessage,
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
                onRefresh: () async => _fetchOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final displayStatus = widget.orderType == 'DELIVERY'
                        ? order.deliveryStatus
                        : order.status;

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
                            color: _getStatusColor(displayStatus ?? ''),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getOrderIcon(widget.orderType),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            if (order.customer?.fullName != null)
                              Text(
                                'Customer: ${order.customer!.fullName}',
                                style: TextStyle(color: AppTheme.textMedium),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      displayStatus ?? '',
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    displayStatus ?? 'Unknown',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        displayStatus ?? '',
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\$${order.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.textLight,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailPage(orderId: order.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
