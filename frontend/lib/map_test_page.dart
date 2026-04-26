import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTestPage extends StatelessWidget {
  const MapTestPage({super.key});

  static const LatLng stockholm = LatLng(59.3293, 18.0686);

  @override
  Widget build(BuildContext context) {
    const LatLng kulturhuset = LatLng(59.3326, 18.0649);
    const LatLng slussen = LatLng(59.3195, 18.0720);
    const LatLng odenplan = LatLng(59.3420, 18.0495);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kulturnatten karta'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: stockholm,
          zoom: 12,
        ),
        markers: const {
          Marker(
            markerId: MarkerId('kulturhuset'),
            position: kulturhuset,
            infoWindow: InfoWindow(title: 'Kulturhuset'),
          ),
          Marker(
            markerId: MarkerId('slussen'),
            position: slussen,
            infoWindow: InfoWindow(title: 'Slussen'),
          ),
          Marker(
            markerId: MarkerId('odenplan'),
            position: odenplan,
            infoWindow: InfoWindow(title: 'Odenplan'),
          ),
        },
        polylines: const {
          Polyline(
            polylineId: PolylineId('route'),
            points: [kulturhuset, slussen, odenplan],
            width: 5,
          ),
        },
      ),
    );
  }
}