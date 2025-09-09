import 'dart:convert';

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
  // ISO-8601 string
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  // epoch millis / seconds
  final i = _asInt(v);
  if (i != null) {
    // đoán: nếu quá nhỏ → seconds, nhân 1000
    final millis = i < 10000000000 ? i * 1000 : i;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return null;
}

class OrderEntity {
  final String id;
  final String orderNumber;
  final dynamic totalPrice;
  final String? status;
  final String? deliveryStatus;
  final dynamic createdAt;

  final CustomerEntity? customer;
  final StaffEntity? staff; // Add staff field
  final List<OrderFoodEntity> foodList;

  final PaymentMethodEntity? paymentMethod;
  final String? voucherCode;
  final dynamic voucherDiscount;

  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryAddress;
  final String? deliveryNote;

  final List<OrderStatusHistoryEntity> statusHistory;

  OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.totalPrice,
    required this.status,
    required this.deliveryStatus,
    required this.createdAt,
    required this.customer,
    this.staff, // Add to constructor
    required this.foodList,
    required this.paymentMethod,
    required this.voucherCode,
    required this.voucherDiscount,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.deliveryNote,
    required this.statusHistory,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> j) {
    final foods = <OrderFoodEntity>[];
    if (j['foodList'] is List) {
      for (final f in (j['foodList'] as List)) {
        if (f is Map<String, dynamic>) foods.add(OrderFoodEntity.fromJson(f));
      }
    }

    final history = <OrderStatusHistoryEntity>[];
    if (j['statusHistory'] is List) {
      for (final h in (j['statusHistory'] as List)) {
        if (h is Map<String, dynamic>) {
          history.add(OrderStatusHistoryEntity.fromJson(h));
        }
      }
    }

    return OrderEntity(
      id: j['id']?.toString() ?? '',
      orderNumber: j['orderNumber']?.toString() ?? '',
      totalPrice: j['totalPrice'],
      status: j['status']?.toString(),
      deliveryStatus: j['deliveryStatus']?.toString(),
      createdAt: j['createdAt'],
      customer: j['customer'] == null
          ? null
          : CustomerEntity.fromJson(j['customer']),
      staff: j['staff'] == null
          ? null
          : StaffEntity.fromJson(j['staff']), // Add staff mapping
      foodList: foods,
      paymentMethod: j['paymentMethod'] == null
          ? null
          : PaymentMethodEntity.fromJson(j['paymentMethod']),
      voucherCode: j['voucherCode']?.toString(),
      voucherDiscount: j['voucherDiscount'],
      recipientName: j['recipientName']?.toString(),
      recipientPhone: j['recipientPhone']?.toString(),
      deliveryAddress: j['deliveryAddress']?.toString(),
      deliveryNote: j['deliveryNote']?.toString(),
      statusHistory: history,
    );
  }

  static List<OrderEntity> listFromJson(dynamic data) {
    if (data is List) {
      return data
          .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    try {
      final decoded = jsonDecode(data.toString());
      if (decoded is List) {
        return decoded.map((e) => OrderEntity.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}

class CustomerEntity {
  final String id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? imageUrl;
  final dynamic point;

  CustomerEntity({
    required this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.imageUrl,
    this.point,
  });

  factory CustomerEntity.fromJson(Map<String, dynamic> j) => CustomerEntity(
    id: j['id']?.toString() ?? '',
    fullName: j['fullName']?.toString(),
    email: j['email']?.toString(),
    phoneNumber: j['phoneNumber']?.toString(),
    imageUrl: j['imageUrl']?.toString(),
    point: j['point'],
  );
}

class OrderFoodEntity {
  final String id;
  final String name;
  final dynamic quantity; // raw
  final dynamic price; // raw

  OrderFoodEntity({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderFoodEntity.fromJson(Map<String, dynamic> j) => OrderFoodEntity(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    quantity: j['quantity'],
    price: j['price'],
  );
}

class OrderStatusHistoryEntity {
  final String status;
  final String? note;
  final String? changedBy;
  final dynamic changedAt; // raw

  OrderStatusHistoryEntity({
    required this.status,
    this.note,
    this.changedBy,
    this.changedAt,
  });

  factory OrderStatusHistoryEntity.fromJson(Map<String, dynamic> j) =>
      OrderStatusHistoryEntity(
        status: j['status']?.toString() ?? '',
        note: j['note']?.toString(),
        changedBy: j['changedBy']?.toString(),
        changedAt: j['changedAt'],
      );
}

class PaymentMethodEntity {
  final String id;
  final String name;
  PaymentMethodEntity({required this.id, required this.name});

  factory PaymentMethodEntity.fromJson(Map<String, dynamic> j) =>
      PaymentMethodEntity(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
      );
}

class StaffEntity {
  final String? name;
  final String? email;

  StaffEntity({this.name, this.email});

  factory StaffEntity.fromJson(Map<String, dynamic> j) =>
      StaffEntity(name: j['name']?.toString(), email: j['email']?.toString());
}
