import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auths/api_service.dart';

class RequestService {
  final ApiService _apiService;

  RequestService(this._apiService);

  String get baseUrl => _apiService.baseUrl;
  http.Client get client => _apiService.client;

  // Fetch requests by status for admin
  Future<List<Map<String, dynamic>>> getRequestsByStatus(String status) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/staff/request?status=$status'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load requests: ${response.statusCode}');
  }

  // Fetch all confirmed requests (approved + denied)
  Future<List<Map<String, dynamic>>> getAllConfirmedRequests() async {
    try {
      final futures = await Future.wait([
        getRequestsByStatus('APPROVED'),
        getRequestsByStatus('DENIED'),
      ]);

      final List<Map<String, dynamic>> allRequests = [];
      for (final requestList in futures) {
        allRequests.addAll(requestList);
      }

      // Sort by request date (newest first)
      allRequests.sort((a, b) {
        final dateA = DateTime.parse(a['requestDate'] ?? '');
        final dateB = DateTime.parse(b['requestDate'] ?? '');
        return dateB.compareTo(dateA);
      });

      return allRequests;
    } catch (e) {
      throw Exception('Failed to load confirmed requests: $e');
    }
  }

  // Approve request (admin)
  Future<void> approveRequest(String requestId, {String? adminNote}) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/staff/$requestId/request/approve'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'adminNote': adminNote ?? ''}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve request: ${response.statusCode}');
    }
  }

  // Deny request (admin)
  Future<void> denyRequest(String requestId, {String? adminNote}) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/staff/$requestId/request/deny'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'adminNote': adminNote ?? ''}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to deny request: ${response.statusCode}');
    }
  }

  // Create new request (staff)
  Future<void> createRequest({
    required String type,
    required String reason,
    required DateTime targetDate,
    String? additionalInfo,
  }) async {
    // Format date as LocalDate (YYYY-MM-DD) for backend
    final formattedDate =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    final requestData = {
      'type': type,
      'reason': reason,
      'targetDate': formattedDate,
      if (additionalInfo != null && additionalInfo.isNotEmpty)
        'additionalInfo': additionalInfo,
    };

    print('Creating request with data: $requestData');

    final response = await client.post(
      Uri.parse('$baseUrl/api/staff/request'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    print('Create request - Status Code: ${response.statusCode}');
    print('Create request - Response Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to create request: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Get staff's own requests - use correct endpoint
  Future<List<Map<String, dynamic>>> getMyRequests() async {
    final response = await client.get(Uri.parse('$baseUrl/api/staff/me'));

    print('getMyRequests - Status Code: ${response.statusCode}');
    print('getMyRequests - Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to load my requests: ${response.statusCode} - ${response.body}',
    );
  }

  // Cancel pending request (staff)
  Future<void> cancelRequest(String requestId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/staff/request/$requestId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel request: ${response.statusCode}');
    }
  }
}
