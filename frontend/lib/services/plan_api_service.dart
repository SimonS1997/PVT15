import 'dart:convert';

import 'package:http/http.dart' as http;

class PlanApiService {
  PlanApiService({required this.baseUrl});

  final String baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 8);

  Future<Map<String, dynamic>> fetchAll(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/preferences'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte hämta preferenser (Status: ${response.statusCode})',
      );
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }

  Future<void> put(String accessToken, String key, dynamic value) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/preferences/$key'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(value),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Kunde inte spara preferens: $key '
        '(Status: ${response.statusCode}, Body: ${response.body})',
      );
    }
  }

  Future<int> deleteAll(String accessToken) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/preferences'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Kunde inte radera');
    }
    return jsonDecode(response.body)['deleted'] ?? 0;
  }
}
