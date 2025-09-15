import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/order_model.dart';
import '../entities/order_entity.dart';
import '../../auths/api_service.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<OrderModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _getOrderById(widget.orderId);
  }

  Future<OrderModel> _getOrderById(String id) async {
    final apiService = context.read<ApiService>();
    final response = await apiService.client.get(
      Uri.parse('${apiService.baseUrl}/api/admin/orders/$id'),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.bodyBytes.isNotEmpty
          ? utf8.decode(response.bodyBytes)
          : '';
      final entity = OrderEntity.fromJson(jsonDecode(body));
      return OrderModel.fromEntity(entity);
    }
    throw Exception(
      'GET order by id -> ${response.statusCode}: ${response.body}',
    );
  }

  void _reload() {
    setState(() {
      _future = _getOrderById(widget.orderId);
    });
  }

  String _fmtMoney(double v) => '${v.toStringAsFixed(0)}đ';
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final order = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text('Created: ${_fmtDate(order.createdAt)}'),
              const SizedBox(height: 6),
              Text('Status: ${order.status}'),
              Text('Delivery Status: ${order.deliveryStatus ?? '—'}'),
              const SizedBox(height: 6),
              Text(
                'Total: ${_fmtMoney(order.totalPrice)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Divider(height: 32),

              // Customer Section
              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(order.customer?.fullName ?? 'Guest'),
                subtitle: Text(order.customer?.email ?? '—'),
              ),
              const Divider(height: 32),

              // Delivery Section
              Text('Delivery', style: Theme.of(context).textTheme.titleMedium),
              _kv('Recipient', order.recipientName),
              _kv('Phone', order.recipientPhone),
              _kv('Address', order.deliveryAddress),
              const Divider(height: 32),

              // Payment Section
              Text('Payment', style: Theme.of(context).textTheme.titleMedium),
              _kv('Method', order.paymentMethod?.name),
              const Divider(height: 32),

              // Items Section
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...order.foodList.map(
                (food) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(food.name),
                  subtitle: Text('x${food.quantity}'),
                  trailing: Text(_fmtMoney(food.price * food.quantity)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String? v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(v == null || v.trim().isEmpty ? '—' : v)),
      ],
    ),
  );
}
