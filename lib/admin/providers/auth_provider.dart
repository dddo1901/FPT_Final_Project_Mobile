import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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

class AuthProvider with ChangeNotifier {
  static const _base = 'http://10.0.2.2:8080/api/auth';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _username;
  String? _role;
  bool _isLoggedIn = false;
  String? _errorMessage;

  String? get token => _token;
  String? get username => _username;
  String? get role => _role;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  /// Đăng nhập
  Future<ApiResult> login(String user, String pass) async {
    final res = await http.post(
      Uri.parse('$_base/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': user, 'password': pass}),
    );
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      _token = d['token'];
      _username = user;

      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'username', value: user);

      _isLoggedIn = true;
      notifyListeners();
      return ApiResult(success: true);
    }

    return ApiResult(success: false, message: 'Login failed');
  }

  /// Gửi lại OTP
  Future<void> resendOtp(String user) async {
    await http.post(
      Uri.parse('$_base/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': user}),
    );
  }

  /// Xác thực OTP
  Future<ApiResult> verifyOtp(String otp) async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      final email = payload['email'] ?? payload['sub'];

      final res = await http.post(
        Uri.parse('$_base/verify-2fa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email, 'code': otp}),
      );

      if (res.statusCode == 200) {
        final List roles = payload['authorities'] ?? [];
        _role = roles.isNotEmpty ? roles.first.replaceAll('ROLE_', '') : '';
        await _storage.write(key: 'role', value: _role);

        notifyListeners();
        return ApiResult(success: true, role: _role ?? '');
      }
    }
    return ApiResult(success: false, message: 'OTP Verification Failed');
  }

  /// Đăng xuất
  Future<void> logout() async {
    _token = null;
    _username = null;
    _role = null;
    _isLoggedIn = false;

    await _storage.delete(key: 'token');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'role');

    notifyListeners();
  }

  /// Tải thông tin đã lưu
  Future<void> loadFromStorage() async {
    _token = await _storage.read(key: 'token');
    _username = await _storage.read(key: 'username');
    _role = await _storage.read(key: 'role');
    _isLoggedIn = _token != null;
    notifyListeners();
  }
}
