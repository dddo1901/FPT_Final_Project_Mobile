import '../entities/order_entity.dart';

class OrderModel {
  final String id; // Sửa từ int sang String để match với Entity
  final String orderNumber;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final CustomerModel? customer;
  final StaffModel? staff; // Add staff field
  final List<FoodOrder> foodList;

  // Thêm các trường mới để hiển thị chi tiết
  final String? deliveryStatus;
  final String? deliveryAddress;
  final String? recipientName;
  final String? recipientPhone;
  final PaymentMethodModel? paymentMethod;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.customer,
    this.staff, // Add to constructor
    required this.foodList,
    this.deliveryStatus,
    this.deliveryAddress,
    this.recipientName,
    this.recipientPhone,
    this.paymentMethod,
  });

  factory OrderModel.fromEntity(OrderEntity e) {
    return OrderModel(
      id: e.id,
      orderNumber: e.orderNumber,
      status: e.status ?? 'UNKNOWN',
      totalPrice: _asDouble(e.totalPrice),
      createdAt: _asDateTime(e.createdAt) ?? DateTime.now(),
      customer: e.customer != null
          ? CustomerModel.fromEntity(e.customer!)
          : null,
      staff: e.staff != null
          ? StaffModel.fromEntity(e.staff!)
          : null, // Map staff from entity
      foodList: e.foodList.map((f) => FoodOrder.fromEntity(f)).toList(),
      deliveryStatus: e.deliveryStatus,
      deliveryAddress: e.deliveryAddress,
      recipientName: e.recipientName,
      recipientPhone: e.recipientPhone,
      paymentMethod: e.paymentMethod != null
          ? PaymentMethodModel.fromEntity(e.paymentMethod!)
          : null,
    );
  }
}

// Thêm model cho PaymentMethod
class PaymentMethodModel {
  final String id;
  final String name;

  PaymentMethodModel({required this.id, required this.name});

  factory PaymentMethodModel.fromEntity(PaymentMethodEntity e) {
    return PaymentMethodModel(id: e.id, name: e.name);
  }
}

// Sửa FoodOrder để map với Entity
class FoodOrder {
  final String id;
  final String name;
  final int quantity;
  final double price;

  FoodOrder({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory FoodOrder.fromEntity(OrderFoodEntity e) {
    return FoodOrder(
      id: e.id,
      name: e.name,
      quantity: _asInt(e.quantity) ?? 1,
      price: _asDouble(e.price),
    );
  }
}

class CustomerModel {
  final String fullName;
  final String? email;

  CustomerModel({required this.fullName, this.email});

  factory CustomerModel.fromEntity(CustomerEntity e) {
    return CustomerModel(
      fullName: e.fullName ?? 'Unknown Customer', // Thêm giá trị mặc định
      email: e.email,
    );
  }
}

// Update StaffModel to include fromEntity factory
class StaffModel {
  final String name;
  final String email;

  StaffModel({required this.name, required this.email});

  factory StaffModel.fromEntity(StaffEntity e) {
    // Add fromEntity constructor
    return StaffModel(name: e.name ?? 'Unknown Staff', email: e.email ?? '');
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      name: json['name'] ?? 'Unknown Staff',
      email: json['email'] ?? '',
    );
  }
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  final millis = _asInt(value);
  if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
  return null;
}
