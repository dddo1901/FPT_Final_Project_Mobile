import '../entities/order_entity.dart';

class OrderModel {
  final String id;
  final String number; // orderNumber
  final double total; // totalPrice normalized
  final String? status; // DELIVERED / CANCELLED
  final String? deliveryStatus; // PREPARING / DELIVERING
  final DateTime? createdAt;

  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAvatar;
  final int? customerPoint;

  final List<OrderItemModel> items;

  final String? paymentMethodName;
  final String? voucherCode;
  final double? voucherDiscount;

  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryAddress;
  final String? deliveryNote;

  final List<OrderStatusChange> history;

  OrderModel({
    required this.id,
    required this.number,
    required this.total,
    required this.status,
    required this.deliveryStatus,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAvatar,
    required this.customerPoint,
    required this.items,
    required this.paymentMethodName,
    required this.voucherCode,
    required this.voucherDiscount,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.deliveryNote,
    required this.history,
  });

  factory OrderModel.fromEntity(OrderEntity e) {
    double _asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int? _asInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    DateTime? _asDateTime(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      final i = _asInt(v);
      if (i != null) {
        final millis = i < 10000000000 ? i * 1000 : i;
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      return null;
    }

    return OrderModel(
      id: e.id,
      number: e.orderNumber,
      total: _asDouble(e.totalPrice),
      status: e.status,
      deliveryStatus: e.deliveryStatus,
      createdAt: _asDateTime(e.createdAt),
      customerName: e.customer?.fullName,
      customerEmail: e.customer?.email,
      customerPhone: e.customer?.phoneNumber,
      customerAvatar: e.customer?.imageUrl,
      customerPoint: _asInt(e.customer?.point),
      items: e.foodList
          .map(
            (f) => OrderItemModel(
              id: f.id,
              name: f.name,
              quantity: _asInt(f.quantity) ?? 1,
              price: _asDouble(f.price),
            ),
          )
          .toList(),
      paymentMethodName: e.paymentMethod?.name,
      voucherCode: e.voucherCode,
      voucherDiscount: e.voucherDiscount == null
          ? null
          : _asDouble(e.voucherDiscount),
      recipientName: e.recipientName,
      recipientPhone: e.recipientPhone,
      deliveryAddress: e.deliveryAddress,
      deliveryNote: e.deliveryNote,
      history: e.statusHistory
          .map(
            (h) => OrderStatusChange(
              status: h.status,
              note: h.note,
              changedBy: h.changedBy,
              changedAt: _asDateTime(h.changedAt),
            ),
          )
          .toList(),
    );
  }

  String get statusBadge => (deliveryStatus ?? status ?? '').isNotEmpty
      ? (deliveryStatus ?? status!)
      : 'UNKNOWN';

  String get createdDate => createdAt != null ? '${createdAt!.toLocal()}' : '—';
}

class OrderItemModel {
  final String id;
  final String name;
  final int quantity;
  final double price;
  const OrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => quantity * price;
}

class OrderStatusChange {
  final String status;
  final String? note;
  final String? changedBy;
  final DateTime? changedAt;
  const OrderStatusChange({
    required this.status,
    this.note,
    this.changedBy,
    this.changedAt,
  });
}
