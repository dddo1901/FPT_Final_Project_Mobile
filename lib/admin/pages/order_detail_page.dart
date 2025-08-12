import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

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
    _future = context.read<OrderService>().getOrderById(widget.orderId);
  }

  void _reload() {
    setState(() {
      _future = context.read<OrderService>().getOrderById(widget.orderId);
    });
  }

  String _fmtMoney(double v) => '${v.toStringAsFixed(0)} đ';
  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final t = d.toLocal().toString();
    return t.substring(0, 16);
  }

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
          final o = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Order #${o.number}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text('Created: ${_fmtDate(o.createdAt)}'),
              const SizedBox(height: 6),
              Text('Status: ${o.status ?? '—'}'),
              Text('Delivery: ${o.deliveryStatus ?? '—'}'),
              const SizedBox(height: 6),
              Text(
                'Total: ${_fmtMoney(o.total)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Divider(height: 32),

              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    (o.customerAvatar != null && o.customerAvatar!.isNotEmpty)
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(o.customerAvatar!),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(o.customerName ?? '—'),
                subtitle: Text(
                  '${o.customerEmail ?? '-'} • ${o.customerPhone ?? '-'}',
                ),
                trailing: (o.customerPoint != null)
                    ? Text('${o.customerPoint} pts')
                    : null,
              ),
              const Divider(height: 32),

              Text('Delivery', style: Theme.of(context).textTheme.titleMedium),
              _kv('Recipient', o.recipientName),
              _kv('Phone', o.recipientPhone),
              _kv('Address', o.deliveryAddress),
              _kv('Note', o.deliveryNote),
              const Divider(height: 32),

              Text('Payment', style: Theme.of(context).textTheme.titleMedium),
              _kv('Method', o.paymentMethodName),
              _kv('Voucher', o.voucherCode),
              _kv(
                'Voucher Discount',
                o.voucherDiscount != null
                    ? _fmtMoney(o.voucherDiscount!)
                    : null,
              ),
              const Divider(height: 32),

              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...o.items.map(
                (it) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(it.name),
                  subtitle: Text('x${it.quantity}'),
                  trailing: Text(_fmtMoney(it.lineTotal)),
                ),
              ),
              const Divider(height: 32),

              if (o.history.isNotEmpty) ...[
                Text('History', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...o.history.map(
                  (h) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(h.status),
                    subtitle: Text(h.note ?? ''),
                    trailing: Text(_fmtDate(h.changedAt)),
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
