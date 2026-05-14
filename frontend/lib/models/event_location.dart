import 'package:google_maps_flutter/google_maps_flutter.dart';

class EventLocation {
  const EventLocation({
    required this.id,
    required this.name,
    required this.venue,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.timeStart,
    this.timeEnd,
    this.district,
    this.description,
    this.nearestStation,
    this.category,
    this.bookingRequired = false,
  });

  final int id;
  final String name;
  final String venue;
  final String address;
  final double latitude;
  final double longitude;
  final String? timeStart;
  final String? timeEnd;
  final String? district;
  final String? description;
  final String? nearestStation;
  final String? category;
  final bool bookingRequired;

  LatLng get position => LatLng(latitude, longitude);

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      id: json['id'] as int,
      name: json['name'] as String,
      venue: json['venue'] as String,
      address: json['address'] as String,
      timeStart: json['timeStart'] as String?,
      timeEnd: json['timeEnd'] as String?,
      district: json['district'] as String?,
      description: json['description'] as String?,
      bookingRequired: json['bookingRequired'] as bool? ?? false,
      nearestStation: json['nearestStation'] as String?,
      category: json['category'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}