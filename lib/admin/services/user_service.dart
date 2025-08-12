import 'dart:convert';
import 'dart:io';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl;
  final http.Client client;
  UserService({required this.baseUrl, required this.client});

  bool _ok(int s) => s >= 200 && s < 300;
  String _decode(http.Response r) =>
      r.bodyBytes.isNotEmpty ? utf8.decode(r.bodyBytes) : '';

  Future<List<UserModel>> getUsers() async {
    final res = await client.get(Uri.parse('$baseUrl/api/auth/users'));
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      final list = (jsonDecode(body) as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
      return list;
    }
    throw Exception('GET users -> ${res.statusCode}: $body');
  }

  Future<UserModel> getUserById(String id) async {
    final res = await client.get(Uri.parse('$baseUrl/api/auth/users/$id'));
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      return UserModel.fromJson(jsonDecode(body));
    }
    throw Exception('GET user/$id -> ${res.statusCode}: $body');
  }

  Future<UserModel> createUser(
    UserModel user, {
    required String password,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final req = http.MultipartRequest('POST', uri)
      ..fields['username'] = user.username
      ..fields['name'] = user.name
      ..fields['email'] = user.email
      ..fields['phone'] = user.phone
      ..fields['role'] = user.role
      ..fields['password'] = password;

    if (user.staffProfile != null) {
      final sp = user.staffProfile!;
      if (sp.position != null) req.fields['position'] = sp.position!;
      if (sp.shiftType != null) req.fields['shiftType'] = sp.shiftType!;
      if (sp.address != null) req.fields['address'] = sp.address!;
      if (sp.dob != null) req.fields['dob'] = sp.dob!;
      if (sp.gender != null) req.fields['gender'] = sp.gender!;
      if (sp.workLocation != null)
        req.fields['workLocation'] = sp.workLocation!;
    }
    if (imageFile != null) {
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamed = await client.send(req);
    final res = await http.Response.fromStream(streamed);
    final body = _decode(res);

    if (_ok(res.statusCode)) {
      if ((res.headers['content-type'] ?? '').contains('application/json') &&
          body.isNotEmpty) {
        return UserModel.fromJson(jsonDecode(body));
      }
      return user;
    }
    throw Exception('Create user failed: ${res.statusCode} $body');
  }

  Future<UserModel> updateUser(
    String id,
    UserModel user, {
    File? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/users/$id');
    final req = http.MultipartRequest('PUT', uri)
      ..fields['username'] = user.username
      ..fields['name'] = user.name
      ..fields['email'] = user.email
      ..fields['phone'] = user.phone
      ..fields['role'] = user.role;

    if (user.staffProfile != null) {
      final sp = user.staffProfile!;
      if (sp.position != null) req.fields['position'] = sp.position!;
      if (sp.shiftType != null) req.fields['shiftType'] = sp.shiftType!;
      if (sp.address != null) req.fields['address'] = sp.address!;
      if (sp.dob != null) req.fields['dob'] = sp.dob!;
      if (sp.gender != null) req.fields['gender'] = sp.gender!;
      if (sp.workLocation != null)
        req.fields['workLocation'] = sp.workLocation!;
    }
    if (imageFile != null) {
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamed = await client.send(req);
    final res = await http.Response.fromStream(streamed);
    final body = _decode(res);
    if (_ok(res.statusCode)) {
      if ((res.headers['content-type'] ?? '').contains('application/json') &&
          body.isNotEmpty) {
        return UserModel.fromJson(jsonDecode(body));
      }
      return getUserById(id);
    }
    throw Exception('Update user failed: ${res.statusCode} $body');
  }

  Future<void> deleteUser(String id) async {
    final res = await client.delete(Uri.parse('$baseUrl/api/auth/users/$id'));
    if (!_ok(res.statusCode)) {
      throw Exception('Delete user failed: ${res.statusCode} ${res.body}');
    }
  }
}
