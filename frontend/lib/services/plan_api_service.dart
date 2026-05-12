import 'dart:convert';

import 'package:http/http.dart' as http;

class PlanApiService {
  PlanApiService({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> fetchAll(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/preferences'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('Kunde inte hämta preferenser');
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }

  Future<int> deleteAll(String accessToken) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/preferences'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('Kunde inte radera');
    }
    return jsonDecode(response.body)['deleted'] ?? 0;
  }
}
