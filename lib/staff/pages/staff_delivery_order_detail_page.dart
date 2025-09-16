import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auths/api_service.dart';
import '../../admin/entities/order_entity.dart';
import '../../admin/models/order_model.dart';

class StaffDeliveryOrderDetailPage extends StatefulWidget {
  final String orderId;
  const StaffDeliveryOrderDetailPage({super.key, required this.orderId});
  @override
  State<StaffDeliveryOrderDetailPage> createState() =>
      _StaffDeliveryOrderDetailPageState();
}

class _StaffDeliveryOrderDetailPageState
    extends State<StaffDeliveryOrderDetailPage> {
  late Future<OrderModel> _future;
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
      return OrderModel.fromEntity(OrderEntity.fromJson(jsonDecode(body)));
    }
    throw Exception('Fetch delivery order ${res.statusCode}: ${res.body}');
  }

  void _reload() => setState(() => _future = _fetch());
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  String _fmtMoney(num v) => '\$${(v / 25000).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Order'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
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
              if (o.deliveryStatus != null)
                _kv('Delivery Status', o.deliveryStatus!),
              _kv('Created', _fmtDate(o.createdAt)),
              _kv('Total', _fmtMoney(o.totalPrice)),
              if (o.paymentMethod != null)
                _kv('Payment', o.paymentMethod!.name),
              const Divider(height: 32),
              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              _kv('Name', o.customer?.fullName ?? '—'),
              _kv('Email', o.customer?.email ?? '—'),
              const Divider(height: 32),
              Text('Delivery', style: Theme.of(context).textTheme.titleMedium),
              _kv('Recipient', o.recipientName ?? '—'),
              _kv('Phone', o.recipientPhone ?? '—'),
              _kv('Address', o.deliveryAddress ?? '—'),
              const Divider(height: 32),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (o.foodList.isEmpty)
                const Text('No items', style: TextStyle(color: Colors.grey))
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
          width: 130,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
