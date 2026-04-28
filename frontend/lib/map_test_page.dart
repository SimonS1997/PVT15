import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/event_location.dart';
import 'services/event_api_service.dart';

class MapTestPage extends StatefulWidget {
  const MapTestPage({
    super.key,
    this.accessToken,
  });

  final String? accessToken;

  @override
  State<MapTestPage> createState() => _MapTestPageState();
}

class _MapTestPageState extends State<MapTestPage> {
  late final Future<List<EventLocation>> _eventsFuture;

  final List<EventLocation> selectedEvents = [];

  @override
  void initState() {
    super.initState();

    final service = EventApiService(
      baseUrl: 'http://10.0.2.2:8080',
    );

    _eventsFuture = service.fetchEvents(accessToken: widget.accessToken);
  }

  Set<Marker> _createMarkers(List<EventLocation> events) {
    return events.map((event) {
      return Marker(
        markerId: MarkerId(event.id.toString()),
        position: event.position,
        infoWindow: InfoWindow(
          title: event.name,
          snippet: event.venue,
        ),
        onTap: () {
          setState(() {
            if (!selectedEvents.any((selected) => selected.id == event.id)) {
              selectedEvents.add(event);
            }
          });
        },
      );
    }).toSet();
  }

  Set<Polyline> _createPolylines() {
    if (selectedEvents.length < 2) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('selected-events-route'),
        points: selectedEvents.map((event) => event.position).toList(),
        width: 5,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    const stockholm = LatLng(59.3293, 18.0686);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kulturnatten karta'),
      ),
      body: FutureBuilder<List<EventLocation>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Kunde inte hämta events:\n${snapshot.error}'),
            );
          }

          final events = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                flex: 2,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: stockholm,
                    zoom: 12,
                  ),
                  markers: _createMarkers(events),
                  polylines: _createPolylines(),
                ),
              ),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(event.name),
                      subtitle: Text('${event.venue}\n${event.address}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            selectedEvents.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}