// lib/admin/pages/order_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});
  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late Future<List<OrderModel>> _future;
  String _searchText = '';
  String _status = 'ALL';
  OrderModel? _selectedOrder;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderService>().getOrders();
  }

  void _reload() {
    setState(() {
      _future = context.read<OrderService>().getOrders();
    });
  }

  String _fmtMoney(double v) => '${v.toStringAsFixed(0)}đ';
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}';

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Search
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _searchText = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Status Filter
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(
                      value: 'DELIVERED',
                      child: Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'CANCELLED',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'ALL'),
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];

                // Apply filters
                final filtered = orders.where((order) {
                  if (_status != 'ALL' && order.status != _status) return false;
                  if (_searchText.isNotEmpty) {
                    final search = _searchText.toLowerCase();
                    return order.orderNumber.toLowerCase().contains(search) ||
                        order.customer?.fullName.toLowerCase().contains(
                              search,
                            ) ==
                            true ||
                        order.staff?.name.toLowerCase().contains(search) ==
                            true;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final order = filtered[i];
                    final isSelected = order.id == _selectedOrder?.id;

                    return Card(
                      elevation: isSelected ? 4 : 1,
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        selected: isSelected,
                        onTap: () => setState(() => _selectedOrder = order),
                        title: Text('#${order.orderNumber}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customer?.fullName ?? 'Guest'),
                            Text(_fmtDate(order.createdAt)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _fmtMoney(order.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Selected Order Details
          if (_selectedOrder != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${_selectedOrder!.orderNumber}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _selectedOrder = null),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Order details...
                  Text(
                    'Customer: ${_selectedOrder!.customer?.fullName ?? 'Guest'}',
                  ),
                  Text('Staff: ${_selectedOrder!.staff?.name ?? 'N/A'}'),
                  Text('Created: ${_fmtDate(_selectedOrder!.createdAt)}'),
                  Text('Total: ${_fmtMoney(_selectedOrder!.totalPrice)}'),
                  const Divider(),
                  const Text('Items:'),
                  ...(_selectedOrder!.foodList.map(
                    (food) => ListTile(
                      dense: true,
                      title: Text(food.name),
                      trailing: Text(
                        '${food.quantity}x ${_fmtMoney(food.price)}',
                      ),
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
