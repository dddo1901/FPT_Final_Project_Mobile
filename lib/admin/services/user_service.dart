import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  final String baseUrl;
  static final storage = FlutterSecureStorage();

  UserService({required this.baseUrl});

  Future<List<UserModel>> getUsers() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/auth/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final data = json.decode(jsonString) as List<dynamic>;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<UserModel> getUserById(String id) async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      return UserModel.fromJson(json.decode(jsonString));
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<UserModel> createUser(
    UserModel user, {
    required String password,
    File? imageFile,
  }) async {
    final token = await storage.read(key: 'token');
    final uri = Uri.parse('$baseUrl/api/auth/register');

    // build request
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    // thêm các field chính
    req.fields['username'] = user.username;
    req.fields['name'] = user.name ?? '';
    req.fields['email'] = user.email ?? '';
    req.fields['phone'] = user.phone ?? '';
    req.fields['role'] = user.role;
    req.fields['password'] = password;

    // staffProfile nếu có
    if (user.staffProfile != null) {
      final sp = user.staffProfile!;
      req.fields['position'] = sp.position ?? '';
      req.fields['shiftType'] = sp.shiftType ?? '';
      req.fields['address'] = sp.address ?? '';
      req.fields['dob'] = sp.dob ?? '';
      req.fields['gender'] = sp.gender ?? '';
      req.fields['workLocation'] = sp.workLocation ?? '';
    }

    // đính kèm ảnh nếu có
    if (imageFile != null) {
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    // gửi và parse response
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return user;
    } else {
      throw Exception('Failed to create user: ${res.statusCode} ${res.body}');
    }
  }

  /// Cập nhật user với multipart/form-data
  Future<UserModel> updateUser(
    UserModel user, {
    String? newPassword,
    File? imageFile,
  }) async {
    final token = await storage.read(key: 'token');
    final uri = Uri.parse('$baseUrl/api/auth/users/${user.id}');

    final req = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token';

    // các field bình thường
    req.fields['username'] = user.username;
    req.fields['name'] = user.name ?? '';
    req.fields['email'] = user.email ?? '';
    req.fields['phone'] = user.phone ?? '';
    req.fields['role'] = user.role;

    // password mới nếu có
    if (newPassword != null && newPassword.isNotEmpty) {
      req.fields['password'] =
          newPassword; // optional :contentReference[oaicite:7]{index=7}
    }

    // staffProfile nếu role = STAFF
    if (user.staffProfile != null) {
      final sp = user.staffProfile!;
      req.fields['position'] = sp.position ?? '';
      req.fields['shiftType'] = sp.shiftType ?? '';
      req.fields['address'] = sp.address ?? '';
      req.fields['dob'] = sp.dob ?? '';
      req.fields['gender'] = sp.gender ?? '';
      req.fields['workLocation'] = sp.workLocation ?? '';
    }

    // ảnh mới nếu có
    if (imageFile != null) {
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      return user;
    } else {
      throw Exception('Failed to update user: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteUser(String id) async {
    final token = await storage.read(key: 'token');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/auth/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }
}
