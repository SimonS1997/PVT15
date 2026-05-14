import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../models/event_location.dart';
import '../services/event_api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'event_map_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final Future<List<EventLocation>> eventsFuture;

  @override
  void initState() {
    super.initState();

    final service = EventApiService(
      baseUrl: 'http://10.0.2.2:8082',
    );

    eventsFuture = _loadEvents(service);
  }

  Future<List<EventLocation>> _loadEvents(EventApiService service) async {
    final token = await AuthService.instance.validAccessToken();
    return service.fetchEvents(accessToken: token);
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/plan');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12001F),
      body: FutureBuilder<List<EventLocation>>(
        future: eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Kunde inte hämta events:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          return EventMapView(
            events: snapshot.data ?? [],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: _onBottomNavTap,
      ),
    );
  }
}