import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage storage;
  String? _token;
  String? _role;

  AuthProvider(this.storage);

  String? get token => _token;
  String? get role => _role;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> load() async {
    _token = await storage.read(key: 'token');
    _role = await storage.read(key: 'role');
    notifyListeners();
  }

  Future<void> login({required String token, required String role}) async {
    _token = token;
    _role = role;
    // print(role); // Removed print for production
    await storage.write(key: 'token', value: token);
    await storage.write(key: 'role', value: role);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    await storage.delete(key: 'token');
    await storage.delete(key: 'role');
    notifyListeners();
  }
}
