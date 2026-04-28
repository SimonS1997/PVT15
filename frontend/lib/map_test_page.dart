import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'auth_service.dart';

class MapTestPage extends StatelessWidget {
  const MapTestPage({super.key});

  static const LatLng stockholm = LatLng(59.3293, 18.0686);

  @override
  Widget build(BuildContext context) {
    const LatLng kulturhuset = LatLng(59.3326, 18.0649);
    const LatLng slussen = LatLng(59.3195, 18.0720);
    const LatLng odenplan = LatLng(59.3420, 18.0495);

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('kulturhuset'),
        position: kulturhuset,
        infoWindow: const InfoWindow(title: 'Kulturhuset'),
      ),
      Marker(
        markerId: const MarkerId('slussen'),
        position: slussen,
        infoWindow: const InfoWindow(title: 'Slussen'),
      ),
      Marker(
        markerId: const MarkerId('odenplan'),
        position: odenplan,
        infoWindow: const InfoWindow(title: 'Odenplan'),
      ),
    };

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: const [kulturhuset, slussen, odenplan],
        width: 5,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kulturnatten karta'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (Route<dynamic> _) => false,
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: stockholm,
          zoom: 12,
        ),
        markers: markers,
        polylines: polylines,
      ),
    );
  }
}