import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/event_location.dart';

class EventMapPage extends StatefulWidget {
  const EventMapPage({
    super.key,
    required this.events,
  });

  final List<EventLocation> events;

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  late final List<EventLocation> selectedEvents;

  @override
  void initState() {
    super.initState();
    selectedEvents = [];
  }

  Set<Marker> get markers {
    return widget.events.map((event) {
      return Marker(
        markerId: MarkerId(event.id.toString()),
        position: event.position,
        infoWindow: InfoWindow(
          title: event.name,
          snippet: event.venue,
        ),
        onTap: () {
          setState(() {
            if (!selectedEvents.contains(event)) {
              selectedEvents.add(event);
            }
          });
        },
      );
    }).toSet();
  }

  Set<Polyline> get polylines {
    if (selectedEvents.length < 2) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('selected-route'),
        points: selectedEvents.map((event) => event.position).toList(),
        width: 5,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    const LatLng stockholm = LatLng(59.3293, 18.0686);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kulturnatten karta'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: stockholm,
                zoom: 12,
              ),
              markers: markers,
              polylines: polylines,
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
                  subtitle: Text(event.venue),
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
      ),
    );
  }
}