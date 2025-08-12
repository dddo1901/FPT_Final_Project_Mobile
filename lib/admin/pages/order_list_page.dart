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
  String _q = '';
  String _status = 'ALL';
  String _dStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderService>().getOrders();
  }

  void _reload() {
    final svc = context.read<OrderService>();
    setState(() {
      _future = svc.getOrders(
        status: _status != 'ALL' ? _status : null,
        deliveryStatus: _dStatus != 'ALL' ? _dStatus : null,
      );
    });
  }

  String _fmtMoney(double v) => '${v.toStringAsFixed(0)} đ';
  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final t = d.toLocal().toString(); // 2025-08-13 10:20
    return t.substring(0, 16);
  }

  Color _chipColor(String s) {
    final x = s.toUpperCase();
    if (x.contains('DELIVERED') || x.contains('SUCCESS')) return Colors.green;
    if (x.contains('CANCEL')) return Colors.redAccent;
    if (x.contains('PREPAR') || x.contains('PENDING')) return Colors.orange;
    if (x.contains('DELIVERING')) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final statusItems = const [
      DropdownMenuItem(
        value: 'ALL',
        child: Text('ALL', overflow: TextOverflow.ellipsis),
      ),
      DropdownMenuItem(
        value: 'DELIVERED',
        child: Text('DELIVERED', overflow: TextOverflow.ellipsis),
      ),
      DropdownMenuItem(
        value: 'CANCELLED',
        child: Text('CANCELLED', overflow: TextOverflow.ellipsis),
      ),
    ];

    final deliveryItems = const [
      DropdownMenuItem(
        value: 'ALL',
        child: Text('ALL', overflow: TextOverflow.ellipsis),
      ),
      DropdownMenuItem(
        value: 'PREPARING',
        child: Text('PREPARING', overflow: TextOverflow.ellipsis),
      ),
      DropdownMenuItem(
        value: 'WAITING_FOR_SHIPPER',
        child: Text('WAITING FOR SHIPPER', overflow: TextOverflow.ellipsis),
      ),
      DropdownMenuItem(
        value: 'DELIVERING',
        child: Text('DELIVERING', overflow: TextOverflow.ellipsis),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                hintText: 'Search order number...',
              ),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),

          // 🔧 Responsive filter bar: Row (>= 520px) / Column (< 520px)
          LayoutBuilder(
            builder: (ctx, constraints) {
              final narrow = constraints.maxWidth < 520;

              final statusField = DropdownButtonFormField<String>(
                isExpanded: true, // tránh overflow ngang
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ALL',
                    child: Text('ALL', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'DELIVERED',
                    child: Text('DELIVERED', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELLED',
                    child: Text('CANCELLED', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (v) {
                  _status = v ?? 'ALL';
                  _reload();
                },
              );

              final deliveryField = DropdownButtonFormField<String>(
                isExpanded: true,
                value: _dStatus,
                decoration: const InputDecoration(
                  labelText: 'Delivery',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ALL',
                    child: Text('ALL', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'PREPARING',
                    child: Text('PREPARING', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'WAITING_FOR_SHIPPER',
                    child: Text(
                      'WAITING FOR SHIPPER',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'DELIVERING',
                    child: Text('DELIVERING', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (v) {
                  _dStatus = v ?? 'ALL';
                  _reload();
                },
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: narrow
                    // 🔹 HẸP: KHÔNG dùng Expanded trong Column
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          statusField,
                          const SizedBox(height: 12),
                          deliveryField,
                        ],
                      )
                    // 🔸 RỘNG: Dùng Expanded trong Row là OK
                    : Row(
                        children: [
                          Expanded(child: statusField),
                          const SizedBox(width: 12),
                          Expanded(child: deliveryField),
                        ],
                      ),
              );
            },
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: FutureBuilder<List<OrderModel>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                var list = snap.data ?? [];
                if (_q.isNotEmpty) {
                  list = list
                      .where(
                        (o) =>
                            o.number.toLowerCase().contains(_q.toLowerCase()),
                      )
                      .toList();
                }
                if (list.isEmpty) return const Center(child: Text('No orders'));

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final o = list[i];
                      final badge = o.statusBadge;
                      return ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/admin/orders/detail',
                            arguments: o.id,
                          ).then((ok) {
                            if (ok == true) _reload();
                          });
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.number,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _chipColor(badge).withOpacity(.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: _chipColor(badge),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(_fmtDate(o.createdAt)),
                        trailing: Text(
                          _fmtMoney(o.total),
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}
