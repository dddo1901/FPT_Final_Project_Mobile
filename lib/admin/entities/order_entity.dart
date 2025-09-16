import 'dart:convert';

class OrderEntity {
  final String id;
  final String orderNumber;
  final dynamic totalPrice;
  final String? status;
  final String? orderType; // Thêm orderType
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
    required this.orderType, // Thêm vào constructor
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

    // Try to parse foodList first (standard orders)
    if (j['foodList'] is List) {
      for (final f in (j['foodList'] as List)) {
        if (f is Map<String, dynamic>) foods.add(OrderFoodEntity.fromJson(f));
      }
    }
    // If no foodList, try orderItems (dine-in orders)
    else if (j['orderItems'] is List) {
      for (final item in (j['orderItems'] as List)) {
        if (item is Map<String, dynamic>) {
          // Convert orderItem to OrderFoodEntity format
          final converted = <String, dynamic>{
            'id':
                item['food']?['id']?.toString() ?? item['id']?.toString() ?? '',
            'name':
                item['food']?['name']?.toString() ??
                item['foodName']?.toString() ??
                'Unknown',
            'price': item['food']?['price'] ?? item['foodPrice'] ?? 0.0,
            'quantity': item['quantity'] ?? 1,
          };
          foods.add(OrderFoodEntity.fromJson(converted));
        }
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
      orderType: j['orderType']?.toString(), // Map orderType từ JSON
      deliveryStatus: j['deliveryStatus']?.toString(),
      createdAt: j['createdAt'],
      customer: j['customer'] == null || j['customer'] is! Map<String, dynamic>
          ? null
          : CustomerEntity.fromJson(j['customer'] as Map<String, dynamic>),
      staff: j['staff'] == null || j['staff'] is! Map<String, dynamic>
          ? null
          : StaffEntity.fromJson(j['staff'] as Map<String, dynamic>),
      foodList: foods,
      paymentMethod:
          j['paymentMethod'] == null ||
              j['paymentMethod'] is! Map<String, dynamic>
          ? null
          : PaymentMethodEntity.fromJson(
              j['paymentMethod'] as Map<String, dynamic>,
            ),
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
          .where((e) => e is Map<String, dynamic>)
          .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    try {
      final decoded = jsonDecode(data.toString());
      if (decoded is List) {
        return decoded
            .where((e) => e is Map<String, dynamic>)
            .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
            .toList();
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
