import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/order_model.dart';
import '../entities/order_entity.dart';
import '../../auths/api_service.dart';
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
      appBar: AppBar(
        title: const Text('Order Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Dine-In'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Take-Away'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Delivery'),
          ],
        ),
      ),
      body: TabBarView(
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
          endpoint = '/api/orders/filter?type=DELIVERY';
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
          final data = jsonDecode(body);
          if (data is List) {
            entities = OrderEntity.listFromJson(data);
          }
        }
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching $type orders: $e');
    }
    return entities.map(OrderModel.fromEntity).toList();
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
        return Colors.orange;
      case 'CONFIRMED':
      case 'PAID':
        return Colors.green;
      case 'PREPARING':
        return Colors.blue;
      case 'READY':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red;
      case 'WAITING_FOR_SHIPPER':
        return Colors.amber;
      case 'DELIVERING':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search orders...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _search = value),
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
                      items: _getStatusOptions().map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _statusFilter = value!),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchOrders,
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
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchOrders,
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
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _search.isNotEmpty || _statusFilter != 'ALL'
                            ? 'No orders match your filters'
                            : widget.emptyMessage,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _fetchOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final displayStatus = widget.orderType == 'DELIVERY'
                        ? order.deliveryStatus
                        : order.status;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(displayStatus ?? ''),
                          child: Text(
                            order.orderNumber.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.customer?.fullName != null)
                              Text('Customer: ${order.customer!.fullName}'),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(displayStatus ?? ''),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    displayStatus ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\$${order.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
