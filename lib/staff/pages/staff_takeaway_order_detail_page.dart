import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auths/api_service.dart';
import '../../admin/entities/order_entity.dart';
import '../../admin/models/order_model.dart';
import '../../styles/app_theme.dart';

class StaffTakeAwayOrderDetailPage extends StatefulWidget {
  final String orderId;
  const StaffTakeAwayOrderDetailPage({super.key, required this.orderId});
  @override
  State<StaffTakeAwayOrderDetailPage> createState() =>
      _StaffTakeAwayOrderDetailPageState();
}

class _StaffTakeAwayOrderDetailPageState
    extends State<StaffTakeAwayOrderDetailPage> {
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
    throw Exception('Fetch takeaway order ${res.statusCode}: ${res.body}');
  }

  void _reload() => setState(() => _future = _fetch());
  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  String _fmtMoney(num v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ultraLightBlue,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Take-Away Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: FutureBuilder<OrderModel>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.connectionState != ConnectionState.done) {
              return Container(
                decoration: BoxDecoration(gradient: AppTheme.bgGradient),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }
            if (snap.hasError) {
              return Container(
                decoration: BoxDecoration(gradient: AppTheme.bgGradient),
                child: Center(
                  child: Text(
                    'Error: ${snap.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
            final o = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Order Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${o.orderNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _statusChip(o.status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Order Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _kv('Created', _fmtDate(o.createdAt)),
                      _kv('Total', _fmtMoney(o.totalPrice)),
                      if (o.paymentMethod != null)
                        _kv('Payment', o.paymentMethod!.name),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Customer Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _kv('Name', o.customer?.fullName ?? '—'),
                      _kv('Email', o.customer?.email ?? '—'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Items Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (o.foodList.isEmpty)
                        const Text(
                          'No items',
                          style: TextStyle(color: AppTheme.textLight),
                        )
                      else ...[
                        ...o.foodList.map(
                          (f) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.ultraLightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        'x${f.quantity}',
                                        style: const TextStyle(
                                          color: AppTheme.textMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _fmtMoney(f.price * f.quantity),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                _fmtMoney(
                                  o.foodList.fold<num>(
                                    0,
                                    (s, f) => s + f.price * f.quantity,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            k,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(color: AppTheme.textDark)),
        ),
      ],
    ),
  );

  Widget _statusChip(String status) {
    Color chipColor;
    switch (status.toUpperCase()) {
      case 'PENDING':
        chipColor = AppTheme.warning;
        break;
      case 'CONFIRMED':
        chipColor = AppTheme.info;
        break;
      case 'PREPARING':
        chipColor = AppTheme.primary;
        break;
      case 'READY':
        chipColor = AppTheme.accentBlue;
        break;
      case 'DELIVERED':
        chipColor = AppTheme.success;
        break;
      case 'CANCELLED':
        chipColor = AppTheme.danger;
        break;
      default:
        chipColor = AppTheme.textMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
