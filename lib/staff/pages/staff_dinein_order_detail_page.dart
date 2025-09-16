import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auths/api_service.dart';
import '../../admin/entities/order_entity.dart';
import '../../admin/models/order_model.dart';

/// Detailed page for Dine-In orders (no delivery section, with fallback items fetch)
class StaffDineInOrderDetailPage extends StatefulWidget {
  final String orderId;
  const StaffDineInOrderDetailPage({super.key, required this.orderId});

  @override
  State<StaffDineInOrderDetailPage> createState() =>
      _StaffDineInOrderDetailPageState();
}

class _StaffDineInOrderDetailPageState
    extends State<StaffDineInOrderDetailPage> {
  late Future<OrderModel> _future;
  static final Map<String, List<FoodOrder>> _dineInItemsCache = {};

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<OrderModel> _fetch() async {
    final api = context.read<ApiService>();
    final res = await api.client.get(
      Uri.parse('${api.baseUrl}/api/orders/${widget.orderId}'),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';
      if (body.isEmpty) throw Exception('Empty body');
      var model = OrderModel.fromEntity(OrderEntity.fromJson(jsonDecode(body)));
      // Fallback fetch if empty
      if (model.foodList.isEmpty) {
        final items = await _fetchDineInItems(widget.orderId, api);
        if (items.isNotEmpty) {
          final newTotal = items.fold<double>(
            0,
            (s, f) => s + f.price * f.quantity,
          );
          model = model.copyWith(foodList: items, totalPrice: newTotal);
        }
      }
      return model;
    }
    throw Exception('Fetch dine-in order ${res.statusCode}: ${res.body}');
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
          final list = <FoodOrder>[];
          for (final it in (j['orderItems'] as List)) {
            if (it is Map<String, dynamic>) {
              final idStr = it['foodId']?.toString() ?? '';
              final name = it['foodName']?.toString() ?? '';
              final qty = int.tryParse(it['quantity']?.toString() ?? '1') ?? 1;
              final price = _parseDouble(it['foodPrice']);
              list.add(
                FoodOrder(id: idStr, name: name, quantity: qty, price: price),
              );
            }
          }
          _dineInItemsCache[id] = list;
          return list;
        }
      }
    } catch (_) {}
    return const [];
  }

  double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  void _reload() => setState(() => _future = _fetch());
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  String _fmtMoney(num v) => '\$${(v / 25000).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dine-In Order'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final o = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Order #${o.orderNumber}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _kv('Status', o.status),
              _kv('Created', _fmtDate(o.createdAt)),
              _kv('Total', _fmtMoney(o.totalPrice)),
              const Divider(height: 32),
              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              _kv('Name', o.customer?.fullName ?? '—'),
              _kv('Email', o.customer?.email ?? '—'),
              const Divider(height: 32),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (o.foodList.isEmpty)
                const Text(
                  'No items (fallback empty)',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                ...o.foodList.map(
                  (f) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      f.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('x${f.quantity}'),
                    trailing: Text(_fmtMoney(f.price * f.quantity)),
                  ),
                ),
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Subtotal: ${_fmtMoney(o.foodList.fold<num>(0, (s, f) => s + f.price * f.quantity))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
