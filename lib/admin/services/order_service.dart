import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/order_entity.dart';
import '../models/order_model.dart';

class OrderService {
  final String baseUrl;
  final http.Client client;
  OrderService({required this.baseUrl, required this.client});

  bool _ok(int s) => s >= 200 && s < 300;
  String _decode(http.Response r) =>
      r.bodyBytes.isNotEmpty ? utf8.decode(r.bodyBytes) : '';

  Future<List<OrderModel>> getOrders({
    String? status,
    String? deliveryStatus,
  }) async {
    final query = <String>[];
    if (status != null && status.isNotEmpty) query.add('status=$status');
    if (deliveryStatus != null && deliveryStatus.isNotEmpty) {
      query.add('deliveryStatus=$deliveryStatus');
    }

    final uri = query.isEmpty
        ? Uri.parse('$baseUrl/api/orders')
        : Uri.parse('$baseUrl/api/orders/filter?${query.join('&')}');

    final res = await client.get(uri);
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      final list = jsonDecode(body);
      final entities = OrderEntity.listFromJson(list);
      return entities.map(OrderModel.fromEntity).toList();
    }
    throw Exception('GET orders -> ${res.statusCode}: $body');
  }

  Future<OrderModel> getOrderById(String id) async {
    final res = await client.get(Uri.parse('$baseUrl/api/orders/$id'));
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      final entity = OrderEntity.fromJson(jsonDecode(body));
      return OrderModel.fromEntity(entity);
    }
    throw Exception('GET order/$id -> ${res.statusCode}: $body');
  }
}
