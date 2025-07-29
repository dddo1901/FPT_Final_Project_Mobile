import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class ApiResult {
  final bool success;
  final bool requireOtp;
  final String role;
  final String message;
  ApiResult({
    required this.success,
    this.requireOtp = false,
    this.role = '',
    this.message = '',
  });
}

class ApiService {
  static const base = 'http://10.0.2.2:8080/api/auth';
  static final storage = FlutterSecureStorage();

  static Future<ApiResult> login(String user, String pass) async {
    final res = await http.post(
      Uri.parse('$base/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': user, 'password': pass}),
    );
    print(res.statusCode);
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      final token = d['token'];
      await storage.write(key: 'token', value: token);
      await storage.write(key: 'username', value: user);
      return ApiResult(success: true);
    }
    return ApiResult(success: false, message: 'Login failed');
  }

  static Future<void> resendOtp(String user) async {
    await http.post(
      Uri.parse('$base/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': user}),
    );
  }

  static Future<ApiResult> verifyOtp(String otp) async {
    final token = await storage.read(key: 'token');
    if (token != null) {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      final email = payload['email'] ?? payload['sub'];

      final res = await http.post(
        Uri.parse('$base/verify-2fa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email, 'code': otp}),
      );
      if (res.statusCode == 200) {
        final List roles = payload['authorities'] ?? [];

        String? role;
        if (roles.isNotEmpty && roles.first is String) {
          role = (roles.first as String).replaceAll('ROLE_', '');
        }

        print('ROLE: $role');
        return ApiResult(success: true, role: role!);
      }
    }
    return ApiResult(success: false, message: 'Invalid OTP.');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer \$token',
    };
  }

  // static Future<http.Response> get(String endpoint) async {
  //   final headers = await getAuthHeaders();
  //   return await http.get(Uri.parse('\$baseUrl/\$endpoint'), headers: headers);
  // }

  // static Future<http.Response> post(
  //   String endpoint,
  //   Map<String, dynamic> body,
  // ) async {
  //   final headers = await getAuthHeaders();
  //   return await http.post(
  //     Uri.parse('\$baseUrl/\$endpoint'),
  //     headers: headers,
  //     body: jsonEncode(body),
  //   );
  // }

  static Future<void> logout() async {
    await storage.deleteAll();
  }
}
