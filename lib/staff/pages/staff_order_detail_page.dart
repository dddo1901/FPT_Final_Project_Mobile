import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auths/api_service.dart';
import '../../admin/entities/order_entity.dart';
import '../../admin/models/order_model.dart';

class StaffOrderDetailPage extends StatefulWidget {
  final String orderId;
  const StaffOrderDetailPage({super.key, required this.orderId});

  @override
  State<StaffOrderDetailPage> createState() => _StaffOrderDetailPageState();
}

class _StaffOrderDetailPageState extends State<StaffOrderDetailPage> {
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
      final entity = OrderEntity.fromJson(jsonDecode(body));
      var model = OrderModel.fromEntity(entity);
      if (model.foodList.isEmpty && _looksLikeDineIn(model)) {
        final dineInItems = await _fetchDineInItems(widget.orderId, api);
        if (dineInItems.isNotEmpty) {
          final newTotal = dineInItems.fold<double>(
            0,
            (s, f) => s + f.price * f.quantity,
          );
          model = model.copyWith(foodList: dineInItems, totalPrice: newTotal);
        }
      }
      return model;
    }
    throw Exception('Fetch order detail ${res.statusCode}: ${res.body}');
  }

  void _reload() => setState(() => _future = _fetch());

  String _fmtMoney(num v) => '\$${(v / 25000).toStringAsFixed(2)}';
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Detail (Staff)'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final o = snap.data!;
          final isDineIn =
              _looksLikeDineIn(o) &&
              (o.recipientName == null || o.recipientName!.trim().isEmpty) &&
              (o.recipientPhone == null || o.recipientPhone!.trim().isEmpty);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Order #${o.orderNumber}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _chip(o.status, Colors.blueGrey),
                  if (o.deliveryStatus != null)
                    _chip(o.deliveryStatus!, Colors.deepPurple),
                ],
              ),
              const SizedBox(height: 12),
              _kv('Created', _fmtDate(o.createdAt)),
              _kv('Total', _fmtMoney(o.totalPrice)),
              if (o.paymentMethod != null)
                _kv('Payment', o.paymentMethod!.name),
              const Divider(height: 32),
              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              _kv('Name', o.customer?.fullName ?? '—'),
              _kv('Email', o.customer?.email ?? '—'),
              const Divider(height: 32),
              if (!isDineIn) ...[
                Text(
                  'Delivery',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _kv('Recipient', o.recipientName ?? '—'),
                _kv('Phone', o.recipientPhone ?? '—'),
                _kv('Address', o.deliveryAddress ?? '—'),
                const Divider(height: 32),
              ],
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (o.foodList.isEmpty)
                const Text(
                  'No items (original + fallback empty)',
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
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );

  Widget _chip(String label, Color base) {
    // Use opacity variants instead of shade (works for any Color)
    return Chip(
      label: Text(
        label.toUpperCase(),
        style: TextStyle(color: Colors.white.withOpacity(0.95)),
      ),
      backgroundColor: base.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  bool _looksLikeDineIn(OrderModel o) {
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
            '[STAFF DINEIN FALLBACK] loaded ${items.length} items for order $id',
          );
          return items;
        }
      } else {
        debugPrint(
          '[STAFF DINEIN FALLBACK] HTTP ${res.statusCode}: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint('[STAFF DINEIN FALLBACK ERROR] $e');
    }
    return const [];
  }

  double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
