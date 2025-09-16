import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/staff_entity.dart';
import '../models/staff_model.dart';

class StaffService {
  final String baseUrl;
  final http.Client client;

  StaffService({required this.baseUrl, required this.client});

  Future<StaffModel> getCurrentStaff() async {
    final response = await client.get(Uri.parse('$baseUrl/api/staff/me'));

    if (response.statusCode == 200) {
      return StaffModel.fromEntity(
        StaffEntity.fromJson(json.decode(response.body)),
      );
    }

    throw Exception('Failed to load staff profile');
  }
}
