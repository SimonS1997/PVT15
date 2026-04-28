import 'package:google_maps_flutter/google_maps_flutter.dart';

class EventLocation {
  const EventLocation({
    required this.id,
    required this.name,
    required this.venue,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String venue;
  final String address;
  final double latitude;
  final double longitude;

  LatLng get position => LatLng(latitude, longitude);

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      id: json['id'] as int,
      name: json['name'] as String,
      venue: json['venue'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}