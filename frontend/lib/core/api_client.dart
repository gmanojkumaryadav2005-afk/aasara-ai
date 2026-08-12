import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;

  ApiResponse({required this.statusCode, required this.data});
}

class ApiClient {
  static const String baseUrl = 'https://aasara-api.onrender.com/api/v1';
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, Map<String, dynamic>? data}) async {
    final payload = data ?? body;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: payload != null ? jsonEncode(payload) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, Map<String, dynamic>? data}) async {
    final payload = data ?? body;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: payload != null ? jsonEncode(payload) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> postForm(String endpoint, Map<String, String> body) async {
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String detail = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('detail')) {
          if (decoded['detail'] is String) {
            detail = decoded['detail'];
          } else {
            detail = jsonEncode(decoded['detail']);
          }
        }
      } catch (_) {}
      throw Exception(detail);
    }
  }
}
