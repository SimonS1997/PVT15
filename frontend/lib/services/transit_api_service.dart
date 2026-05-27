import 'dart:convert';

import 'package:http/http.dart' as http;

class LegSegment {
  const LegSegment({
    required this.type,
    required this.line,
    required this.direction,
    required this.fromName,
    required this.toName,
    required this.durationMinutes,
  });

  final String type;
  final String? line;
  final String? direction;
  final String fromName;
  final String toName;
  final int? durationMinutes;

  bool get isWalk => type.toUpperCase() == 'WALK';

  factory LegSegment.fromJson(Map<String, dynamic> json) => LegSegment(
        type: json['type'] as String,
        line: json['line'] as String?,
        direction: json['direction'] as String?,
        fromName: json['fromName'] as String,
        toName: json['toName'] as String,
        durationMinutes: json['durationMinutes'] as int?,
      );
}

class LegPlanLeg {
  const LegPlanLeg({
    required this.from,
    required this.to,
    required this.travelMinutes,
    required this.segments,
  });

  final String from;
  final String to;
  final int travelMinutes;
  final List<LegSegment> segments;

  factory LegPlanLeg.fromJson(Map<String, dynamic> json) => LegPlanLeg(
        from: json['from'] as String,
        to: json['to'] as String,
        travelMinutes: json['travelMinutes'] as int,
        segments: (json['segments'] as List<dynamic>? ?? [])
            .map((e) => LegSegment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TransitApiService {
  TransitApiService({required this.baseUrl});

  final String baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<List<LegPlanLeg>> planLegs({
    required List<Map<String, dynamic>> stops,
    String? accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/transit/legs'),
      headers: {
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'stops': stops}),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte hämta restider '
        '(Status: ${response.statusCode}, Body: ${response.body})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final legs = (data['legs'] as List<dynamic>)
        .map((e) => LegPlanLeg.fromJson(e as Map<String, dynamic>))
        .toList();
    return legs;
  }
}
