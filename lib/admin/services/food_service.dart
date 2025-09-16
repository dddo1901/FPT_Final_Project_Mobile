import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../entities/food_entity.dart';
import '../models/food_model.dart';

class FoodService {
  final String baseUrl;
  final http.Client client;
  FoodService({required this.baseUrl, required this.client});

  bool _ok(int s) => s >= 200 && s < 300;
  String _dec(http.Response r) =>
      r.bodyBytes.isNotEmpty ? utf8.decode(r.bodyBytes) : '';

  // List/filter -> trả List<FoodModel>
  Future<List<FoodModel>> filterFoods({String name = ''}) async {
    final uri = Uri.parse('$baseUrl/api/foods/filter?name=$name');
    final res = await client.get(uri);
    final body = _dec(res);
    if (_ok(res.statusCode)) {
      final raw = jsonDecode(body);
      final list = (raw is List) ? raw : (raw['content'] as List);
      final entities = list.map((e) => FoodEntity.fromJson(e)).toList();
      return entities
          .map((e) => FoodModel.fromEntity(e, baseUrl: baseUrl))
          .toList();
    }
    throw Exception('GET /api/foods/filter -> ${res.statusCode}: $body');
  }

  // Detail -> trả FoodModel
  Future<FoodModel> getFoodById(String id) async {
    final res = await client.get(Uri.parse('$baseUrl/api/foods/$id'));
    final body = _dec(res);
    if (_ok(res.statusCode)) {
      final e = FoodEntity.fromJson(jsonDecode(body));
      return FoodModel.fromEntity(e, baseUrl: baseUrl);
    }
    throw Exception('GET /api/foods/$id -> ${res.statusCode}: $body');
  }

  // Create (multipart/form-data)
  Future<void> createFood({
    required String name,
    required double price,
    String status = 'AVAILABLE',
    String type = 'OTHER',
    String? description,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/foods/create');
    final req = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['price'] = price.toString()
      ..fields['status'] = status
      ..fields['type'] = type;
    if (description != null && description.trim().isNotEmpty) {
      req.fields['description'] = description.trim();
    }
    if (imageFile != null) {
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    final streamed = await client.send(req);
    final res = await http.Response.fromStream(streamed);
    if (!_ok(res.statusCode)) {
      throw Exception(
        'POST /api/foods/create -> ${res.statusCode}: ${res.body}',
      );
    }
  }

  // Update (multipart/form-data) theo web: POST /api/foods/update/{id}
  Future<void> updateFood(
    String id, {
    required String name,
    required double price,
    required String status,
    required String type,
    String? description,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/foods/update/$id');
    final req = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['price'] = price.toString()
      ..fields['status'] = status
      ..fields['type'] = type;
    if (description != null && description.trim().isNotEmpty) {
      req.fields['description'] = description.trim();
    }
    if (imageFile != null) {
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    final streamed = await client.send(req);
    final res = await http.Response.fromStream(streamed);
    if (!_ok(res.statusCode)) {
      throw Exception(
        'POST /api/foods/update/$id -> ${res.statusCode}: ${res.body}',
      );
    }
  }

  // Đổi trạng thái nhanh (list page)
  Future<void> updateStatus(String id, String status) async {
    final res = await client.put(
      Uri.parse('$baseUrl/api/foods/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (!_ok(res.statusCode)) {
      throw Exception(
        'PUT /api/foods/$id/status -> ${res.statusCode}: ${res.body}',
      );
    }
  }
}
