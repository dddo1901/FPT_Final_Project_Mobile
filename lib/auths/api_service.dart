import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final http.Client client;

  ApiService({required this.baseUrl, required this.client});

  bool _ok(int s) => s >= 200 && s < 300;
  String _decode(http.Response r) =>
      r.bodyBytes.isNotEmpty ? utf8.decode(r.bodyBytes) : '';

  // -------- AUTH --------
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse(
      '$baseUrl/api/auth/login',
    ); // hoặc /signin tuỳ backend
    final res = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return body.isNotEmpty
          ? (jsonDecode(body) as Map<String, dynamic>)
          : <String, dynamic>{};
    }
    throw Exception('Login failed: ${res.statusCode} $body');
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-2fa');
    final res = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      }, // TokenClient sẽ tự add Authorization
      body: jsonEncode({'email': email, 'code': code}),
    );
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return body.isNotEmpty
          ? (jsonDecode(body) as Map<String, dynamic>)
          : <String, dynamic>{};
    }
    throw Exception('Verify OTP failed: ${res.statusCode} $body');
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    // Bạn đang dùng /api/auth/send-mail -> giữ nguyên để khớp backend
    final url = Uri.parse('$baseUrl/api/auth/send-mail');
    final res = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      }, // TokenClient sẽ tự add Authorization nếu không skip
      body: jsonEncode({'email': email}),
    );
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return body.isNotEmpty
          ? (jsonDecode(body) as Map<String, dynamic>)
          : <String, dynamic>{};
    }
    throw Exception('Resend OTP failed: ${res.statusCode} $body');
  }

  // -------- DASHBOARD --------
  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final url = Uri.parse('$baseUrl/api/admin/dashboard/analytics');
    final res = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return body.isNotEmpty
          ? (jsonDecode(body) as Map<String, dynamic>)
          : <String, dynamic>{};
    }
    throw Exception('Get analytics failed: ${res.statusCode} $body');
  }

  Future<Map<String, dynamic>> getCustomerStatistics() async {
    final url = Uri.parse('$baseUrl/api/admin/dashboard/customers');
    final res = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return body.isNotEmpty
          ? (jsonDecode(body) as Map<String, dynamic>)
          : <String, dynamic>{};
    }
    throw Exception('Get customer stats failed: ${res.statusCode} $body');
  }

  Future<Map<String, dynamic>> getRevenueAnalytics({
    String timeRange = 'month',
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/admin/dashboard/revenue?timeRange=$timeRange',
    );
    final res = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return body.isNotEmpty
          ? (jsonDecode(body) as Map<String, dynamic>)
          : <String, dynamic>{};
    }
    throw Exception('Get revenue analytics failed: ${res.statusCode} $body');
  }

  Future<List<dynamic>> getVIPCustomers({int limit = 10}) async {
    final url = Uri.parse(
      '$baseUrl/api/admin/dashboard/vip-customers?limit=$limit',
    );
    final res = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return body.isNotEmpty
          ? (jsonDecode(body) as List<dynamic>)
          : <dynamic>[];
    }
    throw Exception('Get VIP customers failed: ${res.statusCode} $body');
  }
}
