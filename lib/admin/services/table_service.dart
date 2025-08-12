import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/table_entity.dart';

class TableService {
  final String baseUrl;
  final http.Client client;
  TableService({required this.baseUrl, required this.client});

  bool _ok(int s) => s >= 200 && s < 300;
  String _decode(http.Response r) =>
      r.bodyBytes.isNotEmpty ? utf8.decode(r.bodyBytes) : '';

  // List tables
  Future<List<TableEntity>> getTables() async {
    final res = await client.get(Uri.parse('$baseUrl/api/tables'));
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      final data = jsonDecode(body);
      if (data is List) {
        return data.map((e) => TableEntity.fromJson(e)).toList();
      }
      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List)
            .map((e) => TableEntity.fromJson(e))
            .toList();
      }
      throw Exception('Unexpected list response shape');
    }
    throw Exception('GET /api/tables -> ${res.statusCode}: $body');
  }

  // Detail
  Future<TableEntity> getTableById(String id) async {
    final res = await client.get(Uri.parse('$baseUrl/api/tables/$id'));
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return TableEntity.fromJson(jsonDecode(body));
    }
    throw Exception('GET /api/tables/$id -> ${res.statusCode}: $body');
  }

  // Create
  Future<void> createTable(TableEntity e) async {
    final res = await client.post(
      Uri.parse('$baseUrl/api/tables'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'number': e.number, // ✅ key theo web
        'capacity': e.capacity,
        'status': e.status,
        'location': e.location,
        'description': e.description,
      }),
    );
    if (!_ok(res.statusCode)) {
      throw Exception('POST /api/tables -> ${res.statusCode}: ${res.body}');
    }
  }

  // Update
  Future<void> updateTable(String id, TableEntity e) async {
    final res = await client.put(
      Uri.parse('$baseUrl/api/tables/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'number': e.number, // ✅ key theo web
        'capacity': e.capacity,
        'status': e.status,
        'location': e.location,
        'description': e.description,
      }),
    );
    if (!_ok(res.statusCode)) {
      throw Exception('PUT /api/tables/$id -> ${res.statusCode}: ${res.body}');
    }
  }

  // Update status (web có)
  Future<void> updateStatus(String id, String newStatus) async {
    final res = await client.put(
      Uri.parse('$baseUrl/api/tables/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );
    if (!_ok(res.statusCode)) {
      throw Exception(
        'PUT /api/tables/$id/status -> ${res.statusCode}: ${res.body}',
      );
    }
  }
}

// ───── QR Code API
extension TableQrApi on TableService {
  Future<String?> getTableQr(String id) async {
    final res = await client.get(Uri.parse('$baseUrl/api/tables/$id/qr-code'));
    if (!_ok(res.statusCode)) {
      throw Exception(
        'GET /api/tables/$id/qr-code -> ${res.statusCode}: ${res.body}',
      );
    }
    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final raw = (map['qrCode'] ?? '').toString().trim();
    if (raw.isEmpty) return null;

    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('data:image')) return raw;

    // base64 "trần"
    final looksBase64 = !raw.contains('/') && raw.length > 100;
    if (looksBase64) return 'data:image/png;base64,$raw';

    // relative path
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '$normalizedBase$normalizedPath';
  }
}
