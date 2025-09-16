// lib/admin/services/chatbot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auths/api_service.dart';

class ChatbotService {
  final ApiService _apiService;

  ChatbotService(this._apiService);

  String get baseUrl => _apiService.baseUrl;
  http.Client get client => _apiService.client;

  // Sessions Management
  Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/chat/sessions'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load chat sessions: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getSessionDetails(String sessionId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/chat/sessions/$sessionId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load session details: ${response.statusCode}');
  }

  Future<void> deleteSession(String sessionId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/admin/chat/sessions/$sessionId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete session: ${response.statusCode}');
    }
  }

  Future<void> clearAllSessions() async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/admin/chat/sessions/clear-all'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear all sessions: ${response.statusCode}');
    }
  }

  Future<void> handoverSession(String sessionId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/admin/chat/sessions/$sessionId/handover'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to handover session: ${response.statusCode}');
    }
  }

  Future<void> sendAgentMessage(String sessionId, String message) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/admin/chat/sessions/$sessionId/agent-message'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'message': message}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send agent message: ${response.statusCode}');
    }
  }

  // FAQ Management
  Future<List<Map<String, dynamic>>> getFAQs() async {
    final response = await client.get(Uri.parse('$baseUrl/api/admin/chat/faq'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load FAQs: ${response.statusCode}');
  }

  Future<void> createFAQ(Map<String, dynamic> faq) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/admin/chat/faq'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(faq),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create FAQ: ${response.statusCode}');
    }
  }

  Future<void> updateFAQ(String id, Map<String, dynamic> faq) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/admin/chat/faq/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(faq),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update FAQ: ${response.statusCode}');
    }
  }

  Future<void> deleteFAQ(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/admin/chat/faq/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete FAQ: ${response.statusCode}');
    }
  }

  // Knowledge Base Management
  Future<List<Map<String, dynamic>>> getKnowledgeBase() async {
    final response = await client.get(Uri.parse('$baseUrl/api/admin/chat/kb'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load knowledge base: ${response.statusCode}');
  }

  Future<void> createKBArticle(Map<String, dynamic> article) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/admin/chat/kb'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(article),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create KB article: ${response.statusCode}');
    }
  }

  Future<void> updateKBArticle(String id, Map<String, dynamic> article) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/admin/chat/kb/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(article),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update KB article: ${response.statusCode}');
    }
  }

  Future<void> deleteKBArticle(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/admin/chat/kb/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete KB article: ${response.statusCode}');
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getBasicAnalytics() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/chat/analytics/basic'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'totalSessions': 0, 'totalMessages': 0};
  }
}
