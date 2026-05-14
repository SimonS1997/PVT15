import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_location.dart';

class EventApiService {
  EventApiService({required this.baseUrl});

  final String baseUrl;

  Future<List<EventLocation>> fetchEvents({
    String? accessToken,
    String? category,
    String? search,
  }) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;

    var uri = Uri.parse('$baseUrl/api/events');
    if (query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final response = await http.get(
      uri,
      headers: {
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch events: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

    return jsonList
        .map((item) => EventLocation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EventLocation?> fetchById(int id, {String? accessToken}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/events/$id'),
      headers: {
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch event: ${response.statusCode}');
    }

    return EventLocation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
