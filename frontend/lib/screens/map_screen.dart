import 'package:flutter/material.dart';
import '../models/event_location.dart';
import '../services/event_api_service.dart';
import 'event_map_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.accessToken});

  final String? accessToken;

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

    eventsFuture = service.fetchEvents(accessToken: widget.accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventLocation>>(
      future: eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Kunde inte hämta events:\n${snapshot.error}'),
            ),
          );
        }

        return EventMapView(
          events: snapshot.data ?? [],
        );
      },
    );
  }
}