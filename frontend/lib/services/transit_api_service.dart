import 'dart:convert';

import 'package:http/http.dart' as http;

class LegPlanLeg {
  const LegPlanLeg({
    required this.from,
    required this.to,
    required this.travelMinutes,
  });

  final String from;
  final String to;
  final int travelMinutes;

  factory LegPlanLeg.fromJson(Map<String, dynamic> json) => LegPlanLeg(
        from: json['from'] as String,
        to: json['to'] as String,
        travelMinutes: json['travelMinutes'] as int,
      );
}

class TransitApiService {
  TransitApiService({required this.baseUrl});

  final String baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<List<LegPlanLeg>> planLegs({
    required List<Map<String, dynamic>> stops,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/transit/legs'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'stops': stops}),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte hämta restider (Status: ${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final legs = (data['legs'] as List<dynamic>)
        .map((e) => LegPlanLeg.fromJson(e as Map<String, dynamic>))
        .toList();
    return legs;
  }
}
