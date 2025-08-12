// lib/data/services/table_service.dart
import 'dart:convert';
import 'package:fpt_final_project_mobile/admin/entities/table_entity.dart';
import 'package:http/http.dart' as http;

import '../models/table_model.dart';

typedef TokenProvider = Future<String?> Function();

class TableService {
  final String baseUrl;
  final http.Client _client;
  final TokenProvider getToken;

  TableService({
    required this.baseUrl,
    required this.getToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> _headers(String? token) => {
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String _decodeBody(http.Response res) =>
      res.bodyBytes.isNotEmpty ? utf8.decode(res.bodyBytes) : '';

  bool _isOk(int code) => code >= 200 && code < 300;

  Future<List<TableEntity>> getTables() async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/tables');
    final res = await _client.get(uri, headers: _headers(token));
    final body = _decodeBody(res);

    if (_isOk(res.statusCode)) {
      final list = (jsonDecode(body) as List)
          .map((e) => TableModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      return list;
    }
    throw Exception('GET /api/tables -> ${res.statusCode}: $body');
  }

  Future<TableEntity> getTable(String id) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/tables/$id');
    final res = await _client.get(uri, headers: _headers(token));
    final body = _decodeBody(res);

    if (_isOk(res.statusCode)) {
      return TableModel.fromJson(jsonDecode(body)).toEntity();
    }
    throw Exception('GET /api/tables/$id -> ${res.statusCode}: $body');
  }

  Future<TableEntity> createTable(TableEntity e) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/tables');
    final model = TableModel.fromEntity(e);
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(model.toJson()),
    );
    final body = _decodeBody(res);

    if (_isOk(res.statusCode)) {
      // Server có thể trả object hoặc 201/204
      if (res.headers['content-type']?.contains('application/json') == true &&
          body.isNotEmpty) {
        return TableModel.fromJson(jsonDecode(body)).toEntity();
      }
      // fallback: fetch lại list hoặc throw để caller tự handle
      final all = await getTables();
      return all.last; // tạm đoán bản mới nhất
    }
    throw Exception('POST /api/tables -> ${res.statusCode}: $body');
  }

  Future<TableEntity> updateTable(String id, TableEntity e) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/tables/$id');
    final model = TableModel.fromEntity(e);
    final res = await _client.put(
      uri,
      headers: _headers(token),
      body: jsonEncode(model.toJson()),
    );
    final body = _decodeBody(res);

    if (_isOk(res.statusCode)) {
      if (res.headers['content-type']?.contains('application/json') == true &&
          body.isNotEmpty) {
        return TableModel.fromJson(jsonDecode(body)).toEntity();
      }
      return getTable(id); // fallback
    }
    throw Exception('PUT /api/tables/$id -> ${res.statusCode}: $body');
  }

  Future<void> deleteTable(String id) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/tables/$id');
    final res = await _client.delete(uri, headers: _headers(token));
    final body = _decodeBody(res);
    if (!_isOk(res.statusCode)) {
      throw Exception('DELETE /api/tables/$id -> ${res.statusCode}: $body');
    }
  }

  Future<void> updateStatus(String id, TableStatus status) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/tables/$id/status');
    final res = await _client.put(
      uri,
      headers: _headers(token),
      body: jsonEncode({'status': status.toApi()}),
    );
    final body = _decodeBody(res);
    if (!_isOk(res.statusCode)) {
      throw Exception('PUT /status -> ${res.statusCode}: $body');
    }
  }

  Future<String> fetchQrCodeUrl(String id) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/tables/$id/qr-code');
    final res = await _client.get(uri, headers: _headers(token));
    final body = _decodeBody(res);
    if (_isOk(res.statusCode)) {
      final j = jsonDecode(body) as Map<String, dynamic>;
      return (j['qrCode'] ?? '').toString();
    }
    throw Exception('GET /qr-code -> ${res.statusCode}: $body');
  }
}
