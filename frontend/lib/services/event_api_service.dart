import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_location.dart';

class EventApiService {
  EventApiService({required this.baseUrl});

  final String baseUrl;

  Future<List<EventLocation>> fetchEvents({String? accessToken}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/events'),
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
}